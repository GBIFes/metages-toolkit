#' Calcular ICA para las ultimas provisiones publicas de MetaGES
#'
#' Usa conectar_metages() y el calculador Python original de GBIF.
#' @param entorno Entorno de conexion: test (por defecto) o prod.
#' @param provision_ids IDs opcionales. Las provisiones con valores existentes
#'   se calculan para inspeccion, sin escribir.
#' @param write Escribir resultados y errores en MetaGES. Por defecto FALSE.
#' @param python_executable Ejecutable Python del entorno con el plugin instalado.
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
  .ica_python(python_executable, runner, check = TRUE)
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
                      fecha_validacion = NA_character_, status = "omitted", detail = "",
                      stringsAsFactors = FALSE)
    if (!isTRUE(as.logical(row$eligible))) {
      out$detail <- "Provision inexistente, historica o recurso privado"
    } else {
      computed <- tryCatch(.ica_python(python_executable, runner, row$url_ipt), error = identity)
      if (inherits(computed, "error")) {
        out$status <- "error"
        out$detail <- conditionMessage(computed)
        if (write && isTRUE(as.logical(row$empty))) .ica_write(con, row, error = out$detail)
      } else {
        for (field in c("ICA", "Icat", "Icag", "Icad", "fecha_validacion")) out[[field]] <- computed[[field]]
        out$status <- if (!isTRUE(as.logical(row$empty))) "inspection" else "preview"
        if (write && isTRUE(as.logical(row$empty))) {
          out$status <- if (.ica_write(con, row, scores = computed)) "updated" else "changed"
        }
      }
    }
    message(jsonlite::toJSON(out, dataframe = "rows", auto_unbox = TRUE, na = "null"))
    results <- rbind(results, out)
  }
  results
}

.ica_empty_result <- function() {
  data.frame(provision_id = integer(), url_ipt = character(), ICA = double(),
             Icat = double(), Icag = double(), Icad = double(),
             fecha_validacion = character(), status = character(), detail = character())
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
               "(", .ica_empty_sql(), ") AS empty",
               "FROM metages_provision_recurso p JOIN metages_recurso r ON r.recurso_id = p.recurso_fk")
  if (is.null(ids)) {
    sql <- paste(sql, "WHERE r.private = 0 AND", .ica_latest_sql(), "AND", .ica_empty_sql())
    return(DBI::dbGetQuery(con, sql))
  }
  sql <- paste(sql, "WHERE p.provision_id IN (", paste(rep("?", length(ids)), collapse = ","), ")")
  rows <- DBI::dbGetQuery(con, sql, params = as.list(ids))
  missing <- setdiff(ids, rows$provision_id)
  if (length(missing)) rows <- rbind(rows, data.frame(provision_id = missing,
    url_ipt = NA_character_, eligible = FALSE, empty = FALSE))
  rows[match(ids, rows$provision_id), , drop = FALSE]
}

.ica_python <- function(executable, runner, url = NULL, check = FALSE) {
  if (!is.character(executable) || length(executable) != 1L || is.na(executable) || !nzchar(executable))
    stop("python_executable debe identificar un ejecutable")
  input <- if (check) "" else jsonlite::toJSON(list(url_ipt = url), auto_unbox = TRUE, na = "null")
  input_file <- tempfile("ica-input-")
  on.exit(unlink(input_file), add = TRUE)
  writeLines(input, input_file, useBytes = TRUE)
  process <- processx::run(executable, c(runner, if (check) "--check"),
                           stdin = input_file, timeout = if (check) 120 else 3600,
                           error_on_status = FALSE)
  result <- jsonlite::fromJSON(process$stdout)
  if (process$status != 0L || !is.null(result$error)) stop(result$error %||ica% process$stderr)
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
    # Lock the resource so concurrent runs serialize; reselect after the calculation.
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
          DBI::dbExecute(con, "UPDATE metages_provision_recurso SET provision_obs = ? WHERE provision_id = ?",
            params = list(paste(c(if (nzchar(obs)) obs, note), collapse = "\n"), row$provision_id))
        }
      } else {
        DBI::dbExecute(con, paste("UPDATE metages_provision_recurso SET ICA = ?, Icat = ?,",
          "Icag = ?, Icad = ?, fecha_validacion = ? WHERE provision_id = ?"),
          params = c(unname(scores[c("ICA", "Icat", "Icag", "Icad", "fecha_validacion")]), list(row$provision_id)))
      }
      TRUE
    }
  })
}
