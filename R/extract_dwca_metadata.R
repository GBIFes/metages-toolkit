#' Añadir metadatos EML y número de occurrences a una tabla con columna dwca_url
#'
#' @description
#' Procesa una tabla que debe contener una columna llamada `dwca_url` con URLs a
#' archivos ZIP de tipo Darwin Core Archive (DwC-A). Para cada URL:
#' \itemize{
#'   \item descarga el ZIP,
#'   \item lee `eml.xml`,
#'   \item extrae `packageId` y parsea solo la versión (por ejemplo `V2.2`),
#'   \item extrae `pubDate`,
#'   \item lee `meta.xml`,
#'   \item localiza el fichero de occurrences a partir de `rowType` y `location`,
#'   \item cuenta sus registros restando `ignoreHeaderLines`.
#' }
#'
#' Para mejorar la eficiencia, cada URL única se procesa una sola vez aunque
#' aparezca repetida en varias filas.
#'
#' @param df `data.frame` que debe contener una columna llamada `dwca_url`.
#'   Puede incluir columnas adicionales, como por ejemplo `recurso_fk` o
#'   `url_ipt`, que se conservarán en la salida.
#' @param progress Si `TRUE`, muestra progreso por consola.
#'
#' @return
#' El mismo `df` de entrada, conservando sus columnas originales y añadiendo:
#' \itemize{
#'   \item `eml_version`
#'   \item `eml_pub_date`
#'   \item `eml_occurrences`
#'   \item `eml_status`
#'   \item `eml_error_message`
#' }
#'
#' Si una URL no puede procesarse correctamente, las columnas extraídas quedarán
#' como `NA` y el detalle del problema se registrará en `eml_error_message`.
#'
#' @details
#' Esta función asume que:
#' \itemize{
#'   \item la URL del recurso DwC-A está en la columna `dwca_url`
#'   \item la versión está en el atributo `packageId` del nodo raíz de `eml.xml`
#'   \item la fecha está en el nodo `pubDate`
#'   \item el fichero de occurrences está definido en `meta.xml`
#'   \item las líneas de cabecera se indican en el atributo `ignoreHeaderLines`
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
  
  # Obtener URLs únicas válidas para evitar trabajo duplicado.
  urls_unique <- df |>
    dplyr::distinct(dwca_url) |>
    dplyr::filter(!is.na(dwca_url), nzchar(dwca_url))
  
  # Si no hay URLs válidas, devolver el df con columnas vacías añadidas.
  if (nrow(urls_unique) == 0L) {
    return(
      df |>
        dplyr::mutate(
          eml_version = NA_character_,
          eml_pub_date = NA_character_,
          eml_occurrences = NA_integer_,
          eml_status = NA_character_,
          eml_error_message = NA_character_
        )
    )
  }
  
  # Procesar una única URL y devolver una fila con sus metadatos.
  parse_one_url <- function(url) {
    # Inicializar salida por defecto.
    out <- data.frame(
      dwca_url = url,
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
          
          # Extraer packageId del nodo raíz.
          package_id <- xml2::xml_attr(xml2::xml_root(eml_doc), "packageId")
          
          # Parsear solo la parte de versión, por ejemplo V2.2.
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
                
                # Si el fichero existe dentro del ZIP, contar líneas en streaming.
                if (!is.na(occ_idx)) {
                  occ_name <- zip_listing$Name[occ_idx]
                  con <- unz(tmp_zip, occ_name, open = "rb")
                  on.exit(close(con), add = TRUE)
                  
                  n_lines <- 0L
                  
                  repeat {
                    chunk <- readLines(con, n = 100000L, warn = FALSE, encoding = "UTF-8")
                    
                    if (length(chunk) == 0L) {
                      break
                    }
                    
                    n_lines <- n_lines + length(chunk)
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
  
  # Reservar una lista para los resultados por URL única.
  results <- vector("list", nrow(urls_unique))
  
  # Procesar cada URL única una sola vez.
  for (i in seq_len(nrow(urls_unique))) {
    if (isTRUE(progress)) {
      message(sprintf("[%d/%d] Procesando: %s", i, nrow(urls_unique), urls_unique$dwca_url[i]))
    }
    
    results[[i]] <- parse_one_url(urls_unique$dwca_url[i])
  }
  
  # Unir los resultados en una tabla auxiliar por dwca_url.
  metadata_df <- dplyr::bind_rows(results)
  
  # Añadir los metadatos al data frame original conservando todas sus columnas.
  df |>
    dplyr::left_join(metadata_df, by = "dwca_url")
}



#' Comparar snapshot nuevo con el estado actual de monitorización
#'
#' @description
#' Compara un snapshot nuevo extraído desde los DwC-A con el estado actual de
#' `metages_recurso_monitor` ya cargado en memoria y construye dos objetos:
#' \itemize{
#'   \item una tabla para actualizar `metages_recurso_monitor`
#'   \item una tabla para insertar eventos en `metages_recurso_monitor_log`
#' }
#'
#' @param snapshot_df `data.frame` con al menos las columnas:
#'   `recurso_fk`, `eml_version`, `eml_pub_date`, `eml_occurrences`,
#'   `eml_status`, `eml_error_message`.
#' @param current_df `data.frame` con el estado actual de
#'   `metages_recurso_monitor`.
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
compare_recurso_monitor_snapshot <- function(snapshot_df, current_df, checked_at = Sys.time()) {
  # Comprobar que el snapshot tiene las columnas mínimas esperadas.
  required_snapshot_cols <- c(
    "recurso_fk",
    "eml_version",
    "eml_pub_date",
    "eml_occurrences",
    "eml_status",
    "eml_error_message"
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
  
  # Si current_df viene vacío, crear estructura mínima esperada.
  if (nrow(current_df) == 0L) {
    current_df <- data.frame(
      recurso_fk = integer(),
      last_checked_at = as.POSIXct(character()),
      last_change_at = as.POSIXct(character()),
      eml_version_detected = character(),
      eml_pub_date_detected = as.Date(character()),
      occurrences_detected = numeric(),
      monitor_status = character(),
      monitor_error_message = character(),
      stringsAsFactors = FALSE
    )
  }
  
  # Renombrar columnas del estado actual para distinguirlas del snapshot nuevo.
  current_df <- current_df |>
    dplyr::rename(
      current_last_checked_at = last_checked_at,
      current_last_change_at = last_change_at,
      current_eml_version_detected = eml_version_detected,
      current_eml_pub_date_detected = eml_pub_date_detected,
      current_occurrences_detected = occurrences_detected,
      current_monitor_status = monitor_status,
      current_monitor_error_message = monitor_error_message
    )
  
  # Unir snapshot nuevo con estado actual por recurso.
  x <- snapshot_df |>
    dplyr::left_join(current_df, by = "recurso_fk")
  
  # Comparador robusto a NA.
  neq_val <- function(a, b) {
    (is.na(a) & !is.na(b)) |
      (!is.na(a) & is.na(b)) |
      (!is.na(a) & !is.na(b) & a != b)
  }
  
  # Calcular flags de cambio y diferencias respecto al último chequeo.
  x <- x |>
    dplyr::mutate(
      is_new = is.na(current_monitor_status),
      version_changed = neq_val(eml_version, current_eml_version_detected),
      pubdate_changed = neq_val(eml_pub_date, current_eml_pub_date_detected),
      occurrences_changed = neq_val(eml_occurrences, current_occurrences_detected),
      status_changed = neq_val(eml_status, current_monitor_status),
      occurrences_diff_last_check = dplyr::case_when(
        !is.na(eml_occurrences) & !is.na(current_occurrences_detected) ~
          as.numeric(eml_occurrences) - as.numeric(current_occurrences_detected),
        TRUE ~ NA_real_
      )
    )
  
  # Clasificar el tipo de cambio observado.
  x <- x |>
    dplyr::mutate(
      change_type = dplyr::case_when(
        is_new ~ "initial_snapshot",
        eml_status == "error" ~ "error",
        current_monitor_status == "error" & eml_status == "ok" ~ "recovered",
        occurrences_changed ~ "occurrences_changed",
        version_changed | pubdate_changed ~ "metadata_changed",
        TRUE ~ "unchanged"
      ),
      change_detail = dplyr::case_when(
        is_new ~ "initial snapshot",
        eml_status == "error" ~ "download or parse error",
        current_monitor_status == "error" & eml_status == "ok" ~ "resource recovered after previous error",
        version_changed & pubdate_changed & occurrences_changed ~ "version, pubdate, occurrences",
        version_changed & pubdate_changed ~ "version, pubdate",
        version_changed & occurrences_changed ~ "version, occurrences",
        pubdate_changed & occurrences_changed ~ "pubdate, occurrences",
        version_changed ~ "version",
        pubdate_changed ~ "pubdate",
        occurrences_changed ~ "occurrences",
        TRUE ~ "none"
      ),
      change_flag = ifelse(change_type == "unchanged", 0L, 1L),
      last_checked_at = checked_at,
      last_change_at = dplyr::case_when(
        is_new ~ checked_at,
        change_flag == 1L ~ checked_at,
        TRUE ~ current_last_change_at
      )
    )
  
  # Preparar la tabla para UPSERT.
  current_upsert_df <- x |>
    dplyr::transmute(
      recurso_fk = recurso_fk,
      last_checked_at = last_checked_at,
      last_change_at = last_change_at,
      eml_version_detected = eml_version,
      eml_pub_date_detected = eml_pub_date,
      occurrences_detected = eml_occurrences,
      previous_eml_version_detected = current_eml_version_detected,
      previous_eml_pub_date_detected = current_eml_pub_date_detected,
      previous_occurrences_detected = current_occurrences_detected,
      occurrences_diff_last_check = occurrences_diff_last_check,
      monitor_status = eml_status,
      monitor_error_message = eml_error_message,
      change_flag = change_flag,
      change_type = change_type,
      change_detail = change_detail
    )
  
  # Preparar la tabla para INSERT en log.
  log_insert_df <- x |>
    dplyr::filter(change_flag == 1L) |>
    dplyr::transmute(
      recurso_fk = recurso_fk,
      event_at = checked_at,
      event_type = change_type,
      change_detail = change_detail,
      previous_eml_version_detected = current_eml_version_detected,
      new_eml_version_detected = eml_version,
      previous_eml_pub_date_detected = current_eml_pub_date_detected,
      new_eml_pub_date_detected = eml_pub_date,
      previous_occurrences_detected = current_occurrences_detected,
      new_occurrences_detected = eml_occurrences,
      occurrences_diff = occurrences_diff_last_check,
      previous_monitor_status = current_monitor_status,
      new_monitor_status = eml_status,
      monitor_error_message = eml_error_message
    )
  
  list(
    current_upsert_df = current_upsert_df,
    log_insert_df = log_insert_df,
    comparison_df = x
  )
}


#' Ejecutar el workflow completo de monitorización de recursos
#'
#' @description
#' Ejecuta el flujo completo de monitorización:
#' \enumerate{
#'   \item abre una conexión con [conectar_metages()]
#'   \item lee recursos públicos desde `metages_recurso`
#'   \item lee el estado actual desde `metages_recurso_monitor`
#'   \item cierra la conexión antes del procesamiento largo
#'   \item construye `dwca_url` a partir de `url_ipt`
#'   \item transforma `resource` en `archive` solo cuando `archive` no exista ya
#'   \item llama a [extract_dwca_metadata()]
#'   \item reabre conexión
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
  # 1. Abrir conexión solo para leer datos de entrada y estado actual.
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
  
  # Leer recursos monitorizables.
  input_df <- DBI::dbGetQuery(
    con_read,
    "
    SELECT
        r.recurso_id AS recurso_fk,
        TRIM(r.url_ipt) AS url_ipt
    FROM metages_recurso r
    WHERE r.private = 0
      AND r.url_ipt IS NOT NULL
      AND TRIM(r.url_ipt) <> ''
    "
  )
  
  # Leer el estado actual antes del procesamiento largo.
  current_df <- DBI::dbGetQuery(
    con_read,
    "
    SELECT
        m.recurso_fk,
        m.last_checked_at,
        m.last_change_at,
        m.eml_version_detected,
        m.eml_pub_date_detected,
        m.occurrences_detected,
        m.monitor_status,
        m.monitor_error_message
    FROM metages_recurso_monitor m
    "
  )
  
  # Cerrar explícitamente conexión y túnel antes del bloque largo.
  try(DBI::dbDisconnect(con_read), silent = TRUE)
  if (!is.null(ssh_read)) {
    try(ssh::ssh_disconnect(ssh_read), silent = TRUE)
  }
  
  # ------------------------------------------------------------------
  # 2. Si no hay recursos, devolver salida vacía.
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
  # 3. Derivar dwca_url y procesar los DwC-A sin conexión abierta.
  # ------------------------------------------------------------------
  input_df <- input_df |>
    dplyr::mutate(
      dwca_url = dplyr::case_when(
        grepl("archive", url_ipt, fixed = TRUE) ~ url_ipt,
        TRUE ~ sub("resource", "archive", url_ipt, fixed = TRUE)
      ),
      dwca_url = sub("/manage/", "/", dwca_url, fixed = TRUE)
    )
  
  snapshot_df <- extract_dwca_metadata(input_df, progress = progress)
  
  # Comparar con el estado actual ya cargado en memoria.
  cmp <- compare_recurso_monitor_snapshot(
    snapshot_df = snapshot_df,
    current_df = current_df,
    checked_at = checked_at
  )
  
  # ------------------------------------------------------------------
  # 4. Reabrir conexión solo para escribir resultados.
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
  upsert_sql <- "
  INSERT INTO metages_recurso_monitor (
      recurso_fk,
      last_checked_at,
      last_change_at,
      eml_version_detected,
      eml_pub_date_detected,
      occurrences_detected,
      previous_eml_version_detected,
      previous_eml_pub_date_detected,
      previous_occurrences_detected,
      occurrences_diff_last_check,
      monitor_status,
      monitor_error_message,
      change_flag,
      change_type,
      change_detail
  ) VALUES (
      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
  )
  ON DUPLICATE KEY UPDATE
      last_checked_at = VALUES(last_checked_at),
      last_change_at = VALUES(last_change_at),
      eml_version_detected = VALUES(eml_version_detected),
      eml_pub_date_detected = VALUES(eml_pub_date_detected),
      occurrences_detected = VALUES(occurrences_detected),
      previous_eml_version_detected = VALUES(previous_eml_version_detected),
      previous_eml_pub_date_detected = VALUES(previous_eml_pub_date_detected),
      previous_occurrences_detected = VALUES(previous_occurrences_detected),
      occurrences_diff_last_check = VALUES(occurrences_diff_last_check),
      monitor_status = VALUES(monitor_status),
      monitor_error_message = VALUES(monitor_error_message),
      change_flag = VALUES(change_flag),
      change_type = VALUES(change_type),
      change_detail = VALUES(change_detail),
      updated_when = CURRENT_TIMESTAMP
  "
  
  # SQL de INSERT sobre la tabla de log.
  log_insert_sql <- "
  INSERT INTO metages_recurso_monitor_log (
      recurso_fk,
      event_at,
      event_type,
      change_detail,
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
      ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
  )
  "
  
  # Escribir en DB en transacción.
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