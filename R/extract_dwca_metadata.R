#' Anhadir metadatos EML y numero de occurrences a una tabla con columna dwca_url
#'
#' @description
#' Procesa una tabla que debe contener una columna llamada `dwca_url` con URLs a
#' archivos ZIP de tipo Darwin Core Archive (DwC-A). Para cada URL:
#' \itemize{
#'   \item descarga el ZIP,
#'   \item lee `eml.xml`,
#'   \item extrae `title`
#'   \item extrae `packageId` y parsea solo la version (por ejemplo `V2.2`),
#'   \item extrae `pubDate`,
#'   \item lee `meta.xml`,
#'   \item localiza el fichero de occurrences a partir de `rowType` y `location`,
#'   \item cuenta sus registros restando `ignoreHeaderLines`.
#' }
#'
#' Para mejorar la eficiencia, cada URL unica se procesa una sola vez aunque
#' aparezca repetida en varias filas.
#'
#' @param df `data.frame` que debe contener una columna llamada `dwca_url`.
#'   Puede incluir columnas adicionales, como por ejemplo `recurso_fk` o
#'   `url_ipt`, que se conservarán en la salida.
#' @param progress Si `TRUE`, muestra progreso por consola.
#'
#' @return
#' El mismo `df` de entrada, conservando sus columnas originales y anhadiendo:
#' \itemize{
#'   \item `eml_title`
#'   \item `eml_version`
#'   \item `eml_pub_date`
#'   \item `eml_occurrences`
#'   \item `eml_status`
#'   \item `eml_error_message`
#' }
#'
#' Si una URL no puede procesarse correctamente, las columnas extraidas quedarán
#' como `NA` y el detalle del problema se registrará en `eml_error_message`.
#'
#' @details
#' Esta funcion asume que:
#' \itemize{
#'   \item la URL del recurso DwC-A está en la columna `dwca_url`
#'   \item el titulo está en un nodo `title` de `eml.xml`
#'   \item la version está en el atributo `packageId` del nodo raiz de `eml.xml`
#'   \item la fecha está en el nodo `pubDate`
#'   \item el fichero de occurrences está definido en `meta.xml`
#'   \item las lineas de cabecera se indican en el atributo `ignoreHeaderLines`
#' }
#'
#' El conteo de occurrences se realiza en streaming, sin cargar el fichero
#' completo en memoria.
#'
#' @examples
#' \dontrun{
#' out <- extract_dwca_metadata(df)
#' }
#'
#' @export
extract_dwca_metadata <- function(df, progress = TRUE) {
  
  # Comprobar que el input tiene la columna obligatoria.
   if (!"dwca_url" %in% names(df)) {
    stop("La columna 'dwca_url' no existe en `df`.")
  }
  
  # Normalizar la columna dwca_url para trabajar con texto limpio.
  df <- df |>
    dplyr::mutate(
      dwca_url = trimws(as.character(dwca_url))
    )
  
  # Obtener URLs unicas válidas para evitar trabajo duplicado.
  urls_unique <- df |>
    dplyr::distinct(dwca_url) |>
    dplyr::filter(!is.na(dwca_url), nzchar(dwca_url))
  
  # Si no hay URLs válidas, devolver el df con columnas vacias anhadidas.
  if (nrow(urls_unique) == 0L) {
    return(
      df |>
        dplyr::mutate(
          eml_title = NA_character_,
          eml_version = NA_character_,
          eml_pub_date = NA_character_,
          eml_occurrences = NA_integer_,
          eml_status = NA_character_,
          eml_error_message = NA_character_
        )
    )
  }
  
  # Procesar una unica URL y devolver una fila con sus metadatos.
  parse_one_url <- function(url) {
    
    # Inicializar salida por defecto.
    out <- data.frame(
      dwca_url = url,
      eml_title = NA_character_,
      eml_version = NA_character_,
      eml_pub_date = NA_character_,
      eml_occurrences = NA_integer_,
      eml_status = "ok",
      eml_error_message = NA_character_,
      stringsAsFactors = FALSE
    )
    
    # Capturar errores por URL para no interrumpir el procesamiento global.
    tryCatch(
      {
        # Descargar el ZIP a un archivo temporal.
        tmp_zip <- tempfile(fileext = ".zip")
        utils::download.file(url, tmp_zip, mode = "wb", quiet = TRUE)
        on.exit(unlink(tmp_zip, force = TRUE), add = TRUE)
        
        # Listar el contenido del ZIP sin descomprimirlo entero.
        zip_listing <- utils::unzip(tmp_zip, list = TRUE)
        
        # Localizar eml.xml y meta.xml dentro del ZIP.
        eml_idx <- grep("(^|/|\\\\)eml\\.xml$", zip_listing$Name, ignore.case = TRUE)
        meta_idx <- grep("(^|/|\\\\)meta\\.xml$", zip_listing$Name, ignore.case = TRUE)
        
        # Si existe eml.xml, extraerlo y parsearlo.
        if (length(eml_idx) > 0L) {
          # Tomar el primer eml.xml encontrado.
          eml_name <- zip_listing$Name[eml_idx[1]]
          
          # Extraer solo eml.xml a un directorio temporal.
          eml_dir <- tempfile("eml_")
          dir.create(eml_dir, recursive = TRUE, showWarnings = FALSE)
          on.exit(unlink(eml_dir, recursive = TRUE, force = TRUE), add = TRUE)
          
          utils::unzip(tmp_zip, files = eml_name, exdir = eml_dir)
          
          # Leer el XML.
          eml_doc <- xml2::read_xml(file.path(eml_dir, eml_name))
          
          # Extraer el primer title bajo dataset.
          title_node <- xml2::xml_find_first(
            eml_doc,
            "//*[local-name()='dataset']/*[local-name()='title'][1]"
          )
          
          if (!inherits(title_node, "xml_missing")) {
            title_text <- trimws(xml2::xml_text(title_node))
            if (nzchar(title_text)) {
              out$eml_title <- title_text
            }
          }
          
          # Extraer packageId del nodo raiz.
          package_id <- xml2::xml_attr(xml2::xml_root(eml_doc), "packageId")
          
          # Parsear solo la parte de version, por ejemplo V2.2.
          if (!is.na(package_id) && nzchar(package_id)) {
            version_match <- regmatches(
              package_id,
              regexpr("V[0-9]+(?:\\.[0-9]+)*", package_id, ignore.case = TRUE)
            )
            
            if (length(version_match) > 0L && !is.na(version_match)) {
              out$eml_version <- toupper(version_match)
            }
          }
          
          # Extraer pubDate.
          pub_node <- xml2::xml_find_first(eml_doc, "//*[local-name()='pubDate'][1]")
          
          if (!inherits(pub_node, "xml_missing")) {
            pub_text <- trimws(xml2::xml_text(pub_node))
            
            if (nzchar(pub_text)) {
              out$eml_pub_date <- pub_text
            }
          }
        }
        
        # Si existe meta.xml, usarlo para localizar y contar occurrences.
        if (length(meta_idx) > 0L) {
          # Tomar el primer meta.xml encontrado.
          meta_name <- zip_listing$Name[meta_idx[1]]
          
          # Extraer solo meta.xml a un directorio temporal.
          meta_dir <- tempfile("meta_")
          dir.create(meta_dir, recursive = TRUE, showWarnings = FALSE)
          on.exit(unlink(meta_dir, recursive = TRUE, force = TRUE), add = TRUE)
          
          utils::unzip(tmp_zip, files = meta_name, exdir = meta_dir)
          
          # Leer el XML.
          meta_doc <- xml2::read_xml(file.path(meta_dir, meta_name))
          
          # Localizar el bloque core o extension de Occurrence.
          occ_node <- xml2::xml_find_first(
            meta_doc,
            "//*[local-name()='core' or local-name()='extension'][@rowType='http://rs.tdwg.org/dwc/terms/Occurrence'][1]"
          )
          
          # Solo continuar si el bloque existe.
          if (!inherits(occ_node, "xml_missing")) {
            # Leer el atributo ignoreHeaderLines; si falta, usar 0.
            header_lines <- suppressWarnings(as.integer(xml2::xml_attr(occ_node, "ignoreHeaderLines")))
            
            if (is.na(header_lines)) {
              header_lines <- 0L
            }
            
            # Leer location del fichero de occurrences.
            location_node <- xml2::xml_find_first(occ_node, ".//*[local-name()='location'][1]")
            
            if (!inherits(location_node, "xml_missing")) {
              occ_file <- trimws(xml2::xml_text(location_node))
              
              if (nzchar(occ_file)) {
                # Intentar localizar el fichero exactamente.
                occ_idx <- match(occ_file, zip_listing$Name)
                
                # Si no coincide exactamente, buscar por sufijo de ruta.
                if (is.na(occ_idx)) {
                  occ_idx <- grep(
                    paste0("(^|/|\\\\)", gsub("([][{}()+*^$|?.\\\\])", "\\\\\\1", occ_file), "$"),
                    zip_listing$Name
                  )[1]
                }
                
                # Si el fichero existe dentro del ZIP, contar lineas en streaming de forma rápida.
                if (!is.na(occ_idx)) {
                  occ_name <- zip_listing$Name[occ_idx]
                  con <- unz(tmp_zip, occ_name, open = "rb")
                  on.exit(close(con), add = TRUE)
                  
                  # Contar saltos de linea a nivel de bytes evita crear strings en R
                  # y suele ser mucho más rápido que readLines().
                  n_lines <- 0L
                  
                  repeat {
                    chunk <- readBin(con, what = "raw", n = 1024 * 1024 * 16)  # 16 MB por bloque
                    
                    if (length(chunk) == 0L) {
                      break
                    }
                    
                    # Contamos bytes LF (\n). Para CRLF también funciona,
                    # porque cada linea termina igualmente en \n.
                    n_lines <- n_lines + sum(chunk == as.raw(0x0A))
                  }
                  
                  # Restar cabecera y evitar valores negativos.
                  out$eml_occurrences <- max(0L, n_lines - header_lines)
                }
              }
            }
          }
        }
        
        # Devolver la fila calculada.
        out
      },
      error = function(e) {
        # Guardar el error sin romper el procesamiento total.
        out$eml_status <- "error"
        out$eml_error_message <- conditionMessage(e)
        out
      }
    )
  }
  
  # Reservar una lista para los resultados por URL unica.
  results <- vector("list", nrow(urls_unique))
  
  # Procesar cada URL unica una sola vez.
  for (i in seq_len(nrow(urls_unique))) {
    if (isTRUE(progress)) {
      message(sprintf("[%d/%d] Procesando: %s", i, nrow(urls_unique), urls_unique$dwca_url[i]))
    }
    
    results[[i]] <- parse_one_url(urls_unique$dwca_url[i])
  }
  
  # Unir los resultados en una tabla auxiliar por dwca_url.
  metadata_df <- dplyr::bind_rows(results)
  
  # Anhadir los metadatos al data frame original conservando todas sus columnas.
  df |>
    dplyr::left_join(metadata_df, by = "dwca_url")
}



#' Comparar snapshot nuevo con baseline de referencia
#'
#' @description
#' Compara un snapshot nuevo extraido desde los DwC-A con el baseline de
#' referencia que ya viene incluido en `snapshot_df`.
#'
#' Se comparan exactamente estos cuatro campos:
#' \itemize{
#'   \item titulo
#'   \item version
#'   \item fecha
#'   \item numero de occurrences
#' }
#'
#' @param snapshot_df `data.frame` con al menos las columnas:
#'   `recurso_fk`, `tipo_recurso`, `eml_title`, `eml_version`, `eml_pub_date`,
#'   `eml_occurrences`, `eml_status`, `eml_error_message`,
#'   `baseline_reference_date`, `baseline_version`, `baseline_occurrences`,
#'   `baseline_title`.
#' @param checked_at Fecha-hora del chequeo. Por defecto `Sys.time()`.
#'
#' @return
#' Una lista con tres elementos:
#' \itemize{
#'   \item `current_upsert_df`
#'   \item `log_insert_df`
#'   \item `comparison_df`
#' }
#'
#' @export
compare_recurso_monitor_snapshot <- function(snapshot_df, checked_at = Sys.time()) {
  required_snapshot_cols <- c(
    "recurso_fk",
    "tipo_recurso",
    "eml_title",
    "eml_version",
    "eml_pub_date",
    "eml_occurrences",
    "eml_status",
    "eml_error_message",
    "baseline_title",
    "baseline_reference_date",
    "baseline_version",
    "baseline_occurrences"
  )
  
  missing_snapshot_cols <- setdiff(required_snapshot_cols, names(snapshot_df))
  
  if (length(missing_snapshot_cols) > 0L) {
    stop(
      sprintf(
        "A `snapshot_df` le faltan estas columnas: %s",
        paste(missing_snapshot_cols, collapse = ", ")
      )
    )
  }
  
  neq_val <- function(a, b) {
    (is.na(a) & !is.na(b)) |
      (!is.na(a) & is.na(b)) |
      (!is.na(a) & !is.na(b) & a != b)
  }
  
  norm_chr <- function(x) {
    x <- trimws(as.character(x))
    x[x == ""] <- NA_character_
    x
  }
  
  norm_date <- function(x) {
    x <- norm_chr(x)
    as.Date(x)
  }
  
  norm_version <- function(x) {
    x <- norm_chr(x)
    x <- sub("^[Vv]\\s*=\\s*", "", x)
    x <- sub("^[Vv]", "", x)
    x
  }
  
  x <- snapshot_df |>
    dplyr::mutate(
      eml_title_cmp = norm_chr(eml_title),
      baseline_title_cmp = norm_chr(baseline_title),
      eml_version_cmp = norm_version(eml_version),
      baseline_version_cmp = norm_version(baseline_version),
      eml_pub_date_cmp = norm_date(eml_pub_date),
      baseline_reference_date_cmp = norm_date(baseline_reference_date),
      baseline_occurrences_cmp = suppressWarnings(as.numeric(baseline_occurrences)),
      eml_occurrences_cmp = suppressWarnings(as.numeric(eml_occurrences)),
      title_changed = neq_val(eml_title_cmp, baseline_title_cmp),
      version_changed = neq_val(eml_version_cmp, baseline_version_cmp),
      pubdate_changed = neq_val(eml_pub_date_cmp, baseline_reference_date_cmp),
      occurrences_changed = neq_val(eml_occurrences_cmp, baseline_occurrences_cmp),
      occurrences_diff_last_check = dplyr::case_when(
        !is.na(eml_occurrences_cmp) & !is.na(baseline_occurrences_cmp) ~
          eml_occurrences_cmp - baseline_occurrences_cmp,
        TRUE ~ NA_real_
      )
    )
  
  x$change_type <- mapply(
    function(status, title_ch, version_ch, pubdate_ch, occ_ch) {
      if (!is.na(status) && status == "error") {
        return("error")
      }
      
      parts <- c(
        if (isTRUE(title_ch)) "title",
        if (isTRUE(version_ch)) "version",
        if (isTRUE(pubdate_ch)) "pubdate",
        if (isTRUE(occ_ch)) "occurrences"
      )
      
      if (length(parts) == 0L) {
        "unchanged"
      } else {
        paste(parts, collapse = ", ")
      }
    },
    x$eml_status,
    x$title_changed,
    x$version_changed,
    x$pubdate_changed,
    x$occurrences_changed,
    USE.NAMES = FALSE
  )
  
  x <- x |>
    dplyr::mutate(
      change_flag = ifelse(change_type == "unchanged", 0L, 1L),
      last_checked_at = checked_at,
      last_change_at = dplyr::case_when(
        change_flag == 1L ~ checked_at,
        TRUE ~ as.POSIXct(NA)
      )
    )
  
  current_upsert_df <- x |>
    dplyr::transmute(
      recurso_fk = recurso_fk,
      tipo_recurso = tipo_recurso,
      last_checked_at = last_checked_at,
      last_change_at = last_change_at,
      eml_title_detected = eml_title,
      previous_eml_title_detected = baseline_title,
      eml_version_detected = eml_version,
      previous_eml_version_detected = baseline_version,
      eml_pub_date_detected = eml_pub_date,
      previous_eml_pub_date_detected = baseline_reference_date,
      occurrences_detected = eml_occurrences_cmp,
      previous_occurrences_detected = baseline_occurrences_cmp,
      occurrences_diff_last_check = occurrences_diff_last_check,
      monitor_status = eml_status,
      monitor_error_message = eml_error_message,
      change_flag = change_flag,
      change_type = change_type
    )
  
  log_insert_df <- x |>
    dplyr::filter(change_flag == 1L) |>
    dplyr::transmute(
      recurso_fk = recurso_fk,
      tipo_recurso = tipo_recurso,
      event_at = checked_at,
      event_type = change_type,
      previous_eml_title_detected = baseline_title,
      new_eml_title_detected = eml_title,
      previous_eml_version_detected = baseline_version,
      new_eml_version_detected = eml_version,
      previous_eml_pub_date_detected = baseline_reference_date,
      new_eml_pub_date_detected = eml_pub_date,
      previous_occurrences_detected = baseline_occurrences_cmp,
      new_occurrences_detected = eml_occurrences_cmp,
      occurrences_diff = occurrences_diff_last_check,
      previous_monitor_status = NA_character_,
      new_monitor_status = eml_status,
      monitor_error_message = eml_error_message
    )
  
  list(
    current_upsert_df = current_upsert_df,
    log_insert_df = log_insert_df,
    comparison_df = x
  )
}



#' Ejecutar el workflow completo de monitorizacion de recursos
#'
#' @description
#' Ejecuta el flujo completo de monitorizacion:
#' \enumerate{
#'   \item abre una conexion con [conectar_metages()]
#'   \item lee recursos publicos desde `metages_recurso`
#'   \item construye un baseline por recurso usando `metages_provision_recurso`
#'         y `metages_recurso`
#'   \item cierra la conexion antes del procesamiento largo
#'   \item construye `dwca_url` a partir de `url_ipt`
#'   \item transforma `resource` en `archive` solo cuando `archive` no exista ya
#'   \item llama a [extract_dwca_metadata()]
#'   \item reabre conexion
#'   \item actualiza `metages_recurso_monitor`
#'   \item inserta eventos en `metages_recurso_monitor_log`
#' }
#'
#' @param progress Si `TRUE`, muestra progreso por consola.
#' @param checked_at Fecha-hora del chequeo. Por defecto `Sys.time()`.
#'
#' @return
#' Una lista invisible con:
#' \itemize{
#'   \item `input_df`
#'   \item `snapshot_df`
#'   \item `current_upsert_df`
#'   \item `log_insert_df`
#'   \item `comparison_df`
#' }
#'
#' @export
run_recurso_monitor_workflow <- function(progress = TRUE, checked_at = Sys.time()) {
  # ------------------------------------------------------------------
  # 1. Abrir conexion solo para leer datos de entrada y baseline.
  # ------------------------------------------------------------------
  cx_read <- conectar_metages()
  con_read <- cx_read$con
  ssh_read <- cx_read$ssh
  
  on.exit({
    try(DBI::dbDisconnect(con_read), silent = TRUE)
    if (!is.null(ssh_read)) {
      try(ssh::ssh_disconnect(ssh_read), silent = TRUE)
    }
  }, add = TRUE)
  
  # Leer recursos monitorizables junto con baseline resuelto.
  input_df <- DBI::dbGetQuery(
    con_read,
    "
  SELECT
      r.recurso_id AS recurso_fk,
      mt.name AS tipo_recurso,
      TRIM(r.url_ipt) AS url_ipt,
      TRIM(r.title) AS baseline_title,

      COALESCE(
          NULLIF(TRIM(p.provision_fecha), ''),
          NULLIF(SUBSTRING(TRIM(r.created_when), 1, 10), '')
      ) AS baseline_reference_date,

      COALESCE(
          NULLIF(TRIM(p.provision_cantidad), ''),
          NULLIF(TRIM(r.numberOfRecords), '')
      ) AS baseline_occurrences,

      COALESCE(
          NULLIF(TRIM(p.version), ''),
          NULLIF(REPLACE(TRIM(r.datapaper_version), 'v=', ''), '')
      ) AS baseline_version

  FROM metages_recurso r
  LEFT JOIN metages_types mt
    ON r.Tipo_recurso = mt.types_id
  LEFT JOIN (
      SELECT pr1.*
      FROM metages_provision_recurso pr1
      INNER JOIN (
          SELECT
              recurso_fk,
              MAX(provision_fecha) AS max_provision_fecha
          FROM metages_provision_recurso
          WHERE NULLIF(TRIM(provision_fecha), '') IS NOT NULL
          GROUP BY recurso_fk
      ) pr2
        ON pr1.recurso_fk = pr2.recurso_fk
       AND pr1.provision_fecha = pr2.max_provision_fecha
  ) p
    ON r.recurso_id = p.recurso_fk
  WHERE r.url_ipt IS NOT NULL
    AND TRIM(r.url_ipt) <> ''
    AND r.private = 0
       -- LIMIT 10 -- Para pruebas
  "
  )
  
  # Cerrar explicitamente conexion y tunel antes del bloque largo.
  try(DBI::dbDisconnect(con_read), silent = TRUE)
  if (!is.null(ssh_read)) {
    try(ssh::ssh_disconnect(ssh_read), silent = TRUE)
  }
  
  # ------------------------------------------------------------------
  # 2. Si no hay recursos, devolver salida vacia.
  # ------------------------------------------------------------------
  if (nrow(input_df) == 0L) {
    return(
      invisible(
        list(
          input_df = input_df,
          snapshot_df = input_df,
          current_upsert_df = data.frame(),
          log_insert_df = data.frame(),
          comparison_df = data.frame()
        )
      )
    )
  }
  
  # ------------------------------------------------------------------
  # 3. Normalizar baseline y derivar dwca_url.
  # ------------------------------------------------------------------
  input_df <- input_df |>
    dplyr::mutate(
      baseline_title = trimws(as.character(baseline_title)),
      baseline_title = dplyr::na_if(baseline_title, ""),
      baseline_reference_date = trimws(as.character(baseline_reference_date)),
      baseline_reference_date = dplyr::na_if(baseline_reference_date, ""),
      baseline_version = trimws(as.character(baseline_version)),
      baseline_version = dplyr::na_if(baseline_version, ""),
      baseline_occurrences = dplyr::case_when(
        is.na(baseline_occurrences) ~ NA_real_,
        TRUE ~ suppressWarnings(as.numeric(baseline_occurrences))
      ),
      dwca_url = dplyr::case_when(
        grepl("archive", url_ipt, fixed = TRUE) ~ url_ipt,
        TRUE ~ sub("resource", "archive", url_ipt, fixed = TRUE)
      ),
      dwca_url = sub("/manage/", "/", dwca_url, fixed = TRUE)
    )
  
  # Extraer snapshot actual desde IPT/DwC-A.
  snapshot_df <- extract_dwca_metadata(input_df, progress = progress)
  
  # Comparar snapshot contra baseline.
  message("Comparando cambios en recursos IPT...")
  cmp <- compare_recurso_monitor_snapshot(
    snapshot_df = snapshot_df,
    checked_at = checked_at
  )
  
  # ------------------------------------------------------------------
  # 4. Reabrir conexion solo para escribir resultados.
  # ------------------------------------------------------------------
  cx_write <- conectar_metages()
  con_write <- cx_write$con
  ssh_write <- cx_write$ssh
  
  on.exit({
    try(DBI::dbDisconnect(con_write), silent = TRUE)
    if (!is.null(ssh_write)) {
      try(ssh::ssh_disconnect(ssh_write), silent = TRUE)
    }
  }, add = TRUE)
  
  # SQL de UPSERT sobre la tabla current.
  message("Insertando logs en MetaGES...")
  
  upsert_sql <- "
INSERT INTO metages_recurso_monitor (
    recurso_fk,
    tipo_recurso,
    last_checked_at,
    last_change_at,
    eml_title_detected,
    previous_eml_title_detected,
    eml_version_detected,
    previous_eml_version_detected,
    eml_pub_date_detected,
    previous_eml_pub_date_detected,
    occurrences_detected,
    previous_occurrences_detected,
    occurrences_diff_last_check,
    monitor_status,
    monitor_error_message,
    change_flag,
    change_type
) VALUES (
    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
)
ON DUPLICATE KEY UPDATE
    tipo_recurso = VALUES(tipo_recurso),
    last_checked_at = VALUES(last_checked_at),
    last_change_at = VALUES(last_change_at),
    eml_title_detected = VALUES(eml_title_detected),
    previous_eml_title_detected = VALUES(previous_eml_title_detected),
    eml_version_detected = VALUES(eml_version_detected),
    previous_eml_version_detected = VALUES(previous_eml_version_detected),
    eml_pub_date_detected = VALUES(eml_pub_date_detected),
    previous_eml_pub_date_detected = VALUES(previous_eml_pub_date_detected),
    occurrences_detected = VALUES(occurrences_detected),
    previous_occurrences_detected = VALUES(previous_occurrences_detected),
    occurrences_diff_last_check = VALUES(occurrences_diff_last_check),
    monitor_status = VALUES(monitor_status),
    monitor_error_message = VALUES(monitor_error_message),
    change_flag = VALUES(change_flag),
    change_type = VALUES(change_type),
    updated_when = CURRENT_TIMESTAMP
"
  
  # SQL de INSERT sobre la tabla de log.
log_insert_sql <- "
INSERT INTO metages_recurso_monitor_log (
    recurso_fk,
    tipo_recurso,
    event_at,
    event_type,
    previous_eml_title_detected,
    new_eml_title_detected,
    previous_eml_version_detected,
    new_eml_version_detected,
    previous_eml_pub_date_detected,
    new_eml_pub_date_detected,
    previous_occurrences_detected,
    new_occurrences_detected,
    occurrences_diff,
    previous_monitor_status,
    new_monitor_status,
    monitor_error_message
) VALUES (
    ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
)
"
  
  # Escribir en DB en transaccion.
  DBI::dbBegin(con_write)
  
  tryCatch(
    {
      for (i in seq_len(nrow(cmp$current_upsert_df))) {
        DBI::dbExecute(
          con_write,
          upsert_sql,
          params = as.list(cmp$current_upsert_df[i, ])
        )
      }
      
      if (nrow(cmp$log_insert_df) > 0L) {
        for (i in seq_len(nrow(cmp$log_insert_df))) {
          DBI::dbExecute(
            con_write,
            log_insert_sql,
            params = as.list(cmp$log_insert_df[i, ])
          )
        }
      }
      
      DBI::dbCommit(con_write)
    },
    error = function(e) {
      DBI::dbRollback(con_write)
      stop(e)
    }
  )
  
  invisible(
    list(
      input_df = input_df,
      snapshot_df = snapshot_df,
      current_upsert_df = cmp$current_upsert_df,
      log_insert_df = cmp$log_insert_df,
      comparison_df = cmp$comparison_df
    )
  )
}