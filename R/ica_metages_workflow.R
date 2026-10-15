#' Calcular ICA para las ultimas provisiones publicas de MetaGES
#'
#' Usa conectar_metages() y el calculador Python original de GBIF.
#' @param entorno Entorno de conexion: test (por defecto) o prod.
#' @param provision_ids IDs opcionales. Las provisiones con valores existentes
#'   se calculan para inspeccion, sin escribir.
#' @param write Escribir resultados y errores en MetaGES. Por defecto FALSE.
#' @param python_executable Python de base o de un venv existente. El workflow
#'   prepara automaticamente el entorno y las dependencias de calculo.
#'   En Windows identifica el Python de Linux que se ejecuta mediante WSL.
#' @return Data frame de resultados, estados y errores por provision.
#' @export
ica_metages_workflow <- function(entorno = c("test", "prod"),
                                provision_ids = NULL, write = FALSE,
                                python_executable = Sys.getenv("METAGES_ICA_PYTHON", "python")) {
  entorno <- match.arg(entorno)
  if (!is.logical(write) || length(write) != 1L || is.na(write)) stop("write debe ser TRUE o FALSE")
  if (!is.null(provision_ids)) {
    if (!is.numeric(provision_ids) || anyNA(provision_ids) ||
        any(!is.finite(provision_ids) | provision_ids < 1 | provision_ids != floor(provision_ids) |
            provision_ids > .Machine$integer.max)) stop("provision_ids debe contener enteros positivos")
    provision_ids <- unique(as.integer(provision_ids))
    if (!length(provision_ids)) return(.ica_empty_result())
  }
  runner <- .ica_runner_path()
  if (!nzchar(runner)) stop("No se encuentra ica_runner.py; instala el paquete")
  prepared <- .ica_python(python_executable, runner, check = TRUE, update = TRUE)
  python_executable <- prepared$python_executable %||ica% python_executable
  connection <- conectar_metages(entorno = entorno)
  on.exit({
    try(DBI::dbDisconnect(connection$con), silent = TRUE)
    try(connection$tunnel$kill(), silent = TRUE)
  }, add = TRUE)
  con <- connection$con
  rows <- .ica_candidates(con, provision_ids)
  results <- .ica_empty_result()
  for (i in seq_len(nrow(rows))) {
    row <- rows[i, , drop = FALSE]
    out <- data.frame(provision_id = row$provision_id, url_ipt = row$url_ipt,
                      ICA = NA_real_, Icat = NA_real_, Icag = NA_real_, Icad = NA_real_,
                      fecha_validacion = NA_character_,
                      status = "omitted", detail = "",
                      stringsAsFactors = FALSE)
    if (!isTRUE(as.logical(row$eligible))) {
      reason <- row$omission_reason
      out$detail <- if (length(reason) == 1L && !is.na(reason) && nzchar(reason)) reason else
        "Provision no elegible; comprueba que sea la ultima de un recurso publico"
    } else {
      computed <- tryCatch(.ica_python(python_executable, runner, row$url_ipt), error = identity)
      if (inherits(computed, "error")) {
        out$status <- "error"
        out$detail <- conditionMessage(computed)
        if (write && isTRUE(as.logical(row$ica_fields_empty))) .ica_write(con, row, error = out$detail)
      } else {
        for (field in c("ICA", "Icat", "Icag", "Icad", "fecha_validacion")) out[[field]] <- computed[[field]]
        out$status <- if (!isTRUE(as.logical(row$ica_fields_empty))) "inspection" else "preview"
        if (write && isTRUE(as.logical(row$ica_fields_empty))) {
          out$status <- if (.ica_write(con, row, scores = computed)) "updated" else "changed"
        }
      }
    }
    message(jsonlite::toJSON(out, dataframe = "rows", auto_unbox = TRUE, na = "null", digits = NA))
    results <- rbind(results, out)
  }
  results
}

.ica_empty_result <- function() {
  data.frame(provision_id = integer(), url_ipt = character(), ICA = double(),
             Icat = double(), Icag = double(), Icad = double(),
             fecha_validacion = character(),
             status = character(), detail = character())
}

.ica_runner_path <- function() system.file("python", "ica_runner.py", package = "metagesToolkit")

.ica_latest_sql <- function() {
  paste("NOT EXISTS (SELECT 1 FROM metages_provision_recurso newer",
        "WHERE newer.recurso_fk = p.recurso_fk AND (",
        "(newer.provision_fecha IS NOT NULL AND p.provision_fecha IS NULL) OR",
        "newer.provision_fecha > p.provision_fecha OR",
        "(newer.provision_fecha <=> p.provision_fecha AND newer.provision_id > p.provision_id)))")
}

.ica_empty_sql <- function() {
  paste("p.ICA IS NULL AND p.Icat IS NULL AND p.Icag IS NULL",
        "AND p.Icad IS NULL AND p.fecha_validacion IS NULL")
}

.ica_candidates <- function(con, ids = NULL) {
  sql <- paste("SELECT p.provision_id, r.url_ipt,",
               "(r.private = 0 AND", .ica_latest_sql(), ") AS eligible,",
               "CASE WHEN r.private IS NULL THEN 'Privacidad del recurso no definida en MetaGES'",
               "WHEN r.private <> 0 THEN 'Recurso marcado como privado en MetaGES'",
               "WHEN NOT (", .ica_latest_sql(), ") THEN 'Provision historica: existe otra mas reciente para este recurso'",
               "ELSE '' END AS omission_reason,",
               "(", .ica_empty_sql(), ") AS ica_fields_empty",
               "FROM metages_provision_recurso p JOIN metages_recurso r ON r.recurso_id = p.recurso_fk")
  if (is.null(ids)) {
    sql <- paste(sql, "WHERE r.private = 0 AND", .ica_latest_sql(), "AND", .ica_empty_sql())
    return(DBI::dbGetQuery(con, sql))
  }
  sql <- paste(sql, "WHERE p.provision_id IN (", paste(rep("?", length(ids)), collapse = ","), ")")
  rows <- DBI::dbGetQuery(con, sql, params = as.list(ids))
  if (!"omission_reason" %in% names(rows)) rows$omission_reason <- rep("", nrow(rows))
  missing <- setdiff(ids, rows$provision_id)
  if (length(missing)) rows <- rbind(rows, data.frame(provision_id = missing,
    url_ipt = NA_character_, eligible = FALSE,
    omission_reason = "Provision inexistente o sin recurso asociado en este entorno de MetaGES",
    ica_fields_empty = FALSE))
  rows[match(ids, rows$provision_id), , drop = FALSE]
}

.ica_use_wsl <- function() .Platform$OS.type == "windows"

.ica_wsl_executable <- function() unname(Sys.which("wsl.exe"))

.ica_run_python <- function(executable, runner, args, input_file, timeout) {
  if (!.ica_use_wsl()) return(processx::run(executable, c(runner, args),
    stdin = input_file, timeout = timeout, error_on_status = FALSE))

  wsl <- .ica_wsl_executable()
  if (!nzchar(wsl)) stop("Se necesita WSL con una distribucion Linux y Python 3; no se encuentra wsl.exe")
  distro <- Sys.getenv("METAGES_ICA_WSL_DISTRO", "")
  prefix <- if (nzchar(distro)) c("--distribution", distro) else character()
  windows_path <- function(path) grepl("^[A-Za-z]:[/\\\\]|^[/\\\\]{2}", path)
  linux_path <- function(path) {
    converted <- processx::run(wsl, c(prefix, "--exec", "wslpath", "-a", "-u", path),
      timeout = 30, error_on_status = FALSE)
    if (converted$status != 0L || !nzchar(trimws(converted$stdout)))
      stop(paste("No se pudo acceder a WSL. Comprueba su distribucion Linux:",
                 converted$stderr, converted$stdout), call. = FALSE)
    trimws(converted$stdout)
  }
  if (windows_path(executable) || grepl("\\.exe$", executable, ignore.case = TRUE))
    stop("En Windows, python_executable debe identificar Python dentro de WSL, por ejemplo python3")
  if (identical(executable, "python")) executable <- "python3"
  runner <- linux_path(normalizePath(runner, winslash = "/", mustWork = TRUE))
  # Pasar solo la configuracion ICA, sin depender de WSLENV ni de una shell.
  environment <- character()
  for (key in c("METAGES_ICA_VENV", "METAGES_ICA_CATALOGUE_DIR")) {
    value <- Sys.getenv(key, "")
    if (nzchar(value)) {
      if (windows_path(value)) value <- linux_path(value)
      environment <- c(environment, paste0(key, "=", value))
    }
  }
  processx::run(wsl, c(prefix, "--exec", "env", environment, executable, runner, args),
    stdin = input_file, timeout = timeout, error_on_status = FALSE)
}

.ica_python <- function(executable, runner, url = NULL, check = FALSE, update = FALSE) {
  if (!is.character(executable) || length(executable) != 1L || is.na(executable) || !nzchar(executable))
    stop("python_executable debe identificar un ejecutable")
  input <- if (check) "" else jsonlite::toJSON(list(url_ipt = url), auto_unbox = TRUE, na = "null")
  input_file <- tempfile("ica-input-")
  on.exit(unlink(input_file), add = TRUE)
  writeLines(input, input_file, useBytes = TRUE)
  process <- .ica_run_python(executable, runner,
    c(if (check) "--check", if (update) "--prepare"), input_file,
    timeout = if (check && !update) 120 else 3600)
  # Un ejecutable ausente o un fallo de arranque puede no producir ningun JSON.
  failure <- function(reason) {
    diagnostics <- c(
      paste0("Python (", executable, "), codigo de salida ", process$status, ": ", reason),
      if (nzchar(trimws(process$stderr))) paste0("stderr: ", substr(process$stderr, 1L, 4000L)),
      if (nzchar(trimws(process$stdout))) paste0("stdout: ", substr(process$stdout, 1L, 4000L)))
    stop(paste(diagnostics, collapse = "\n"), call. = FALSE)
  }
  if (!nzchar(trimws(process$stdout))) failure("El proceso no devolvio resultados JSON")
  result <- tryCatch(jsonlite::fromJSON(process$stdout),
                     error = function(error) failure("El proceso devolvio una salida que no es JSON valido"))
  if (!is.list(result) || is.null(names(result))) failure("La respuesta JSON no es un objeto de resultados")
  if (process$status != 0L || !is.null(result$error))
    failure(if (is.character(result$error) && length(result$error) == 1L && !is.na(result$error))
      result$error else "El proceso fallo")
  if (check) {
    if (!isTRUE(result$ready)) stop("Python no esta preparado")
  } else {
    fields <- c("ICA", "Icat", "Icag", "Icad")
    if (!all(vapply(fields, function(k) is.numeric(result[[k]]) &&
                    length(result[[k]]) == 1L && is.finite(result[[k]]), logical(1))) ||
        length(result$fecha_validacion) != 1L || is.na(as.Date(result$fecha_validacion)))
      stop("Resultado ICA incompleto o invalido")
  }
  result
}

`%||ica%` <- function(x, y) if (is.null(x)) y else x

.ica_write <- function(con, row, scores = NULL, error = NULL) {
  DBI::dbWithTransaction(con, {
    # Bloquear el recurso y revalidar la provision tras el calculo.
    resource <- DBI::dbGetQuery(con, paste("SELECT r.recurso_id FROM metages_recurso r",
      "JOIN metages_provision_recurso p ON p.recurso_fk = r.recurso_id",
      "WHERE p.provision_id = ? FOR UPDATE"), params = list(row$provision_id))
    current <- DBI::dbGetQuery(con, paste("SELECT p.provision_obs FROM metages_provision_recurso p",
      "JOIN metages_recurso r ON r.recurso_id = p.recurso_fk",
      "WHERE p.provision_id = ? AND r.private = 0 AND r.url_ipt = ? AND",
      .ica_latest_sql(), "AND", .ica_empty_sql(), "FOR UPDATE"),
      params = list(row$provision_id, row$url_ipt))
    if (!nrow(resource) || !nrow(current)) FALSE else {
      if (!is.null(error)) {
        marker <- paste("[ICA]", substr(gsub("[\r\n]+", " ", error), 1, 2000))
        obs <- current$provision_obs[[1]]
        if (is.na(obs)) obs <- ""
        if (!grepl(marker, obs, fixed = TRUE)) {
          note <- paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), marker)
          DBI::dbExecute(con, paste("UPDATE metages_provision_recurso SET provision_obs = ?,",
            "updated_when = CURRENT_TIMESTAMP, updated_who = 'ica_metages_workflow' WHERE provision_id = ?"),
            params = list(paste(c(if (nzchar(obs)) obs, note), collapse = "\n"), row$provision_id))
        }
      } else {
        DBI::dbExecute(con, paste("UPDATE metages_provision_recurso SET ICA = ?, Icat = ?,",
          "Icag = ?, Icad = ?, fecha_validacion = ?, updated_when = CURRENT_TIMESTAMP,",
          "updated_who = 'ica_metages_workflow' WHERE provision_id = ?"),
          params = c(unname(scores[c("ICA", "Icat", "Icag", "Icad", "fecha_validacion")]), list(row$provision_id)))
      }
      TRUE
    }
  })
}
