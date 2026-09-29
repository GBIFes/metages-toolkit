# Aplicar una pausa validada entre bloques de peticiones a GBIF.
.gbif_sleep <- function(seconds) {
  seconds <- suppressWarnings(as.numeric(seconds[1]))
  if (!is.na(seconds) && seconds > 0) {
    Sys.sleep(seconds)
  }
}


# Devolver un valor por defecto cuando un campo JSON no existe.
.gbif_or <- function(x, default) {
  if (is.null(x) || length(x) == 0L) default else x
}


# Ejecutar una peticion GET con el protocolo HTTP comun del cliente GBIF.
.gbif_api_perform <- function(
    path,
    query = list(),
    accept_http_errors = FALSE
) {
  request <- httr2::request(paste0("https://api.gbif.org/v1", path))

  if (length(query) > 0L) {
    request <- do.call(httr2::req_url_query, c(list(request), query))
  }

  request <- request |>
    httr2::req_user_agent("metagesToolkit (https://gbifes.github.io/metages-toolkit)") |>
    httr2::req_timeout(seconds = 30) |>
    httr2::req_retry(max_tries = 3)

  if (isTRUE(accept_http_errors)) {
    request <- request |>
      httr2::req_error(is_error = function(response) FALSE)
  }

  httr2::req_perform(request)
}


# Realizar una peticion GET a la API de GBIF y devolver el JSON como lista.
.gbif_api_get_json <- function(path, query = list()) {
  .gbif_api_perform(path, query = query) |>
    httr2::resp_body_json(simplifyVector = FALSE)
}


# Realizar una peticion GET a la API de GBIF y parsear la respuesta como XML.
.gbif_api_get_xml <- function(path) {
  .gbif_api_perform(path) |>
    httr2::resp_body_raw() |>
    xml2::read_xml()
}


# Normalizar una version de GBIF al formato producido por el packageId del EML.
.gbif_extract_version <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[1])) {
    return(NA_character_)
  }

  x <- trimws(as.character(x[1]))
  if (!nzchar(x)) {
    return(NA_character_)
  }

  # El JSON de GBIF suele omitir la V que si aparece en el packageId.
  if (grepl("^[0-9]+(?:\\.[0-9]+)*$", x)) {
    x <- paste0("V", x)
  }

  version_match <- regmatches(
    x,
    regexpr("V[0-9]+(?:\\.[0-9]+)*", x, ignore.case = TRUE)
  )

  if (length(version_match) == 0L || is.na(version_match)) {
    return(NA_character_)
  }

  toupper(version_match)
}


# Extraer un UUID de dataset de un UUID suelto o de una URL de GBIF.
.gbif_dataset_uuid <- function(x) {
  uuid_pattern <- paste0(
    "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-",
    "[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
  )
  match <- regexpr(uuid_pattern, x, perl = TRUE)

  if (match[1] < 0L) {
    return(NA_character_)
  }

  tolower(regmatches(x, match)[1])
}


# Obtener el identificador `r` habitual de una URL de recurso IPT.
.gbif_ipt_resource_key <- function(x) {
  match <- regexec("[?&]r=([^&#]+)", x, ignore.case = TRUE, perl = TRUE)
  parts <- regmatches(x, match)[[1]]

  if (length(parts) < 2L || !nzchar(parts[2])) {
    return(NA_character_)
  }

  tolower(utils::URLdecode(parts[2]))
}


# Normalizar una URL para comparar endpoints sin diferencias cosmeticas.
.gbif_normalize_endpoint <- function(x) {
  x <- trimws(tolower(as.character(x)))
  x <- sub("^https?://", "", x)
  x <- sub("^www\\.", "", x)
  sub("/$", "", x)
}


# Obtener el primer endpoint DWC_ARCHIVE registrado para un dataset.
.gbif_dwca_endpoint <- function(dataset) {
  endpoints <- .gbif_or(dataset$endpoints, list())

  dwca_urls <- vapply(
    endpoints,
    function(endpoint) {
      endpoint_type <- as.character(.gbif_or(endpoint$type, ""))
      if (!identical(endpoint_type, "DWC_ARCHIVE")) {
        return(NA_character_)
      }
      as.character(.gbif_or(endpoint$url, NA_character_))
    },
    character(1)
  )
  dwca_urls <- dwca_urls[!is.na(dwca_urls) & nzchar(dwca_urls)]

  if (length(dwca_urls) == 0L) {
    stop("GBIF no proporciona un endpoint DWC_ARCHIVE para el fallback.")
  }

  dwca_urls[1]
}


# Localizar dentro de un ZIP el fichero declarado en meta.xml.
.gbif_zip_entry <- function(location, zip_names) {
  normalized_location <- gsub("\\", "/", location, fixed = TRUE)
  normalized_location <- sub("^\\./", "", normalized_location)
  normalized_names <- gsub("\\", "/", zip_names, fixed = TRUE)
  idx <- match(normalized_location, normalized_names)

  if (is.na(idx)) {
    suffix <- paste0("/", normalized_location)
    idx <- which(endsWith(normalized_names, suffix))[1]
  }

  if (is.na(idx)) NA_character_ else zip_names[idx]
}


# Contar en streaming las filas de un rowType concreto dentro de un DwC-A.
.gbif_count_dwca_row_type <- function(dwca_url, row_type) {
  tmp_zip <- tempfile(fileext = ".zip")
  utils::download.file(dwca_url, tmp_zip, mode = "wb", quiet = TRUE)
  on.exit(unlink(tmp_zip, force = TRUE), add = TRUE)

  zip_listing <- utils::unzip(tmp_zip, list = TRUE)
  meta_idx <- grep(
    "(^|/|\\\\)meta\\.xml$",
    zip_listing$Name,
    ignore.case = TRUE
  )

  if (length(meta_idx) == 0L) {
    stop("El DwC-A no contiene meta.xml.")
  }

  meta_name <- zip_listing$Name[meta_idx[1]]
  meta_dir <- tempfile("meta_")
  dir.create(meta_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(meta_dir, recursive = TRUE, force = TRUE), add = TRUE)
  utils::unzip(tmp_zip, files = meta_name, exdir = meta_dir)
  meta_doc <- xml2::read_xml(file.path(meta_dir, meta_name))

  data_node <- xml2::xml_find_first(
    meta_doc,
    sprintf(
      "//*[local-name()='core' or local-name()='extension'][@rowType='%s'][1]",
      row_type
    )
  )

  if (inherits(data_node, "xml_missing")) {
    stop(sprintf("meta.xml no declara el rowType requerido: %s", row_type))
  }

  location_node <- xml2::xml_find_first(
    data_node,
    ".//*[local-name()='location'][1]"
  )
  if (inherits(location_node, "xml_missing")) {
    stop("El rowType requerido no contiene un elemento location.")
  }

  location <- trimws(xml2::xml_text(location_node))
  if (!nzchar(location)) {
    stop("El elemento location del rowType requerido esta vacio.")
  }

  data_name <- .gbif_zip_entry(location, zip_listing$Name)
  if (is.na(data_name)) {
    stop(sprintf("No se encontro en el DwC-A la tabla declarada: %s", location))
  }

  header_lines <- suppressWarnings(
    as.integer(xml2::xml_attr(data_node, "ignoreHeaderLines"))
  )
  if (is.na(header_lines)) {
    header_lines <- 0L
  }

  con <- unz(tmp_zip, data_name, open = "rb")
  on.exit(close(con), add = TRUE)

  n_lines <- 0
  has_bytes <- FALSE
  last_byte <- raw(0)

  repeat {
    chunk <- readBin(con, what = "raw", n = 1024 * 1024 * 16)
    if (length(chunk) == 0L) {
      break
    }

    has_bytes <- TRUE
    last_byte <- chunk[length(chunk)]
    n_lines <- n_lines + sum(chunk == as.raw(0x0A))
  }

  if (has_bytes && last_byte != as.raw(0x0A)) {
    n_lines <- n_lines + 1
  }

  n_records <- max(0, n_lines - header_lines)
  if (n_records > .Machine$integer.max) {
    stop("El conteo del DwC-A excede el rango integer del output.")
  }

  as.integer(n_records)
}


# Traducir el tipo de recurso MetaGES al rowType usado en el fallback.
.gbif_fallback_row_type <- function(tipo_recurso_id) {
  tipo_recurso_id <- suppressWarnings(as.integer(tipo_recurso_id[1]))
  if (is.na(tipo_recurso_id)) {
    return(NA_character_)
  }

  if (tipo_recurso_id %in% c(223L, 224L)) {
    return("http://rs.tdwg.org/dwc/terms/Occurrence")
  }
  if (identical(tipo_recurso_id, 225L)) {
    return("http://rs.tdwg.org/dwc/terms/Taxon")
  }

  NA_character_
}


# Resolver una URL DwC-A contra los datasets registrados en GBIF.
.gbif_dataset_key_from_dwca <- function(url) {
  resource_key <- .gbif_ipt_resource_key(url)
  search_terms <- unique(c(url, resource_key))
  search_terms <- search_terms[!is.na(search_terms) & nzchar(search_terms)]
  candidates <- list()

  for (term in search_terms) {
    response <- .gbif_api_get_json(
      "/dataset/search",
      query = list(q = term, limit = 100)
    )

    if (!is.null(response$results)) {
      candidates <- c(candidates, response$results)
    }
  }

  if (length(candidates) == 0L) {
    stop("GBIF no encontro ningun dataset asociado a la URL DwC-A.")
  }

  candidate_keys <- unique(vapply(
    candidates,
    function(candidate) as.character(.gbif_or(candidate$key, NA_character_)),
    character(1)
  ))
  candidate_keys <- candidate_keys[!is.na(candidate_keys) & nzchar(candidate_keys)]

  exact_matches <- character()
  resource_matches <- character()
  input_endpoint <- .gbif_normalize_endpoint(url)

  for (key in candidate_keys) {
    dataset <- .gbif_api_get_json(paste0("/dataset/", key))
    endpoints <- dataset$endpoints

    if (is.null(endpoints) || length(endpoints) == 0L) {
      next
    }

    dwca_urls <- vapply(
      endpoints,
      function(endpoint) {
        endpoint_type <- as.character(.gbif_or(endpoint$type, ""))
        if (!identical(endpoint_type, "DWC_ARCHIVE")) {
          return(NA_character_)
        }
        as.character(.gbif_or(endpoint$url, NA_character_))
      },
      character(1)
    )
    dwca_urls <- dwca_urls[!is.na(dwca_urls) & nzchar(dwca_urls)]

    if (any(.gbif_normalize_endpoint(dwca_urls) == input_endpoint)) {
      exact_matches <- c(exact_matches, key)
      next
    }

    if (!is.na(resource_key)) {
      endpoint_resource_keys <- vapply(
        dwca_urls,
        .gbif_ipt_resource_key,
        character(1)
      )
      if (any(endpoint_resource_keys == resource_key, na.rm = TRUE)) {
        resource_matches <- c(resource_matches, key)
      }
    }
  }

  matches <- unique(if (length(exact_matches) > 0L) exact_matches else resource_matches)

  if (length(matches) == 0L) {
    stop("GBIF no encontro un endpoint DWC_ARCHIVE que coincida con la URL.")
  }
  if (length(matches) > 1L) {
    stop("La URL DwC-A coincide con mas de un dataset de GBIF.")
  }

  matches[1]
}


#' Extraer metadatos de recursos MetaGES mediante GBIF
#'
#' @description
#' Consulta el registro y el indice de ocurrencias de GBIF. Cada valor de
#' `dwca_url` puede ser una URL al DwC-A, un UUID de dataset de GBIF o una URL
#' de dataset de GBIF.
#'
#' Las entradas unicas se consultan una sola vez. Para las URLs DwC-A, la
#' funcion busca el dataset en GBIF y comprueba que su endpoint
#' `DWC_ARCHIVE` coincida con la URL o con el identificador `r` del recurso IPT.
#'
#' @param df `data.frame` que debe contener una columna llamada `dwca_url`.
#'   Puede contener `tipo_recurso_id`; los valores 223, 224 y 225 activan el
#'   fallback selectivo al DwC-A cuando GBIF devuelve cero occurrences. Las
#'   demas columnas se conservan sin cambios.
#' @param progress Si `TRUE`, muestra progreso por consola.
#' @param request_delay Pausa en segundos entre datasets. No altera la lógica
#'   de extracción ni de conteo.
#' @param dataset_details Lista opcional nombrada por UUID con detalles de
#'   datasets GBIF ya obtenidos. Si contiene el UUID solicitado, se reutiliza
#'   su contenido; en caso contrario, se consulta la API de GBIF.
#'
#' @return
#' El mismo `df` de entrada, con las columnas adicionales `eml_title`,
#' `eml_version`, `eml_pub_date`, `eml_occurrences`, `eml_status` y
#' `eml_error_message`.
#'
#' @details
#' La version se obtiene primero del registro JSON de GBIF. Solo si no esta
#' disponible se localiza el documento EML fuente registrado en GBIF y se
#' extrae su atributo `packageId`.
#'
#' Cuando GBIF devuelve cero occurrences, los tipos 223 y 224 cuentan el
#' rowType Occurrence del DwC-A y el tipo 225 cuenta el rowType Taxon. El tipo
#' 226 y los demas tipos conservan el cero de GBIF.
#'
#' `eml_occurrences` representa los registros actualmente indexados por GBIF.
#' Por ello puede diferir temporalmente del numero de filas del DwC-A publicado.
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   dwca_url = "https://www.gbif.org/dataset/837381f4-f762-11e1-a439-00145eb45e9a"
#' )
#' .gbif_extract_dataset_metadata(df)
#' }
#'
.gbif_extract_dataset_metadata <- function(
    df,
    progress = TRUE,
    request_delay = 0.2,
    dataset_details = NULL
) {
  if (!"dwca_url" %in% names(df)) {
    stop("La columna 'dwca_url' no existe en `df`.")
  }

  df <- df |>
    dplyr::mutate(dwca_url = trimws(as.character(dwca_url)))

  has_resource_type <- "tipo_recurso_id" %in% names(df)

  if (has_resource_type) {
    inputs_unique <- df |>
      dplyr::distinct(dwca_url, tipo_recurso_id) |>
      dplyr::filter(!is.na(dwca_url), nzchar(dwca_url))
  } else {
    inputs_unique <- df |>
      dplyr::distinct(dwca_url) |>
      dplyr::filter(!is.na(dwca_url), nzchar(dwca_url)) |>
      dplyr::mutate(tipo_recurso_id = NA_integer_)
  }

  if (nrow(inputs_unique) == 0L) {
    return(
      df |>
        dplyr::mutate(
          eml_title = NA_character_,
          eml_version = NA_character_,
          eml_pub_date = NA_character_,
          eml_occurrences = NA_integer_,
          detected_dwca_url = NA_character_,
          detected_eml_url = NA_character_,
          eml_status = NA_character_,
          eml_error_message = NA_character_
        )
    )
  }

  parse_one_input <- function(input, tipo_recurso_id) {
    out <- data.frame(
      dwca_url = input,
      tipo_recurso_id = suppressWarnings(as.integer(tipo_recurso_id)),
      eml_title = NA_character_,
      eml_version = NA_character_,
      eml_pub_date = NA_character_,
      eml_occurrences = NA_integer_,
      detected_dwca_url = NA_character_,
      detected_eml_url = NA_character_,
      eml_status = "ok",
      eml_error_message = NA_character_,
      stringsAsFactors = FALSE
    )

    tryCatch(
      {
        dataset_key <- .gbif_dataset_uuid(input)
        if (is.na(dataset_key)) {
          dataset_key <- .gbif_dataset_key_from_dwca(input)
        }

        dataset <- if (
          !is.null(dataset_details) &&
          !is.null(dataset_details[[dataset_key]])
        ) {
          dataset_details[[dataset_key]]
        } else {
          .gbif_api_get_json(paste0("/dataset/", dataset_key))
        }
        endpoint_urls <- .gbif_extract_dataset_endpoints(dataset)
        out$detected_dwca_url <- endpoint_urls$dwca_url
        out$detected_eml_url <- endpoint_urls$eml_url
        occurrence <- .gbif_api_get_json(
          "/occurrence/search",
          query = list(dataset_key = dataset_key, limit = 0)
        )

        title <- trimws(as.character(.gbif_or(dataset$title, NA_character_)))
        if (!is.na(title) && nzchar(title)) {
          out$eml_title <- title
        }

        # Usar primero la version ya disponible en el registro JSON de GBIF.
        out$eml_version <- .gbif_extract_version(dataset$version)

        # Descargar el EML fuente solo como respaldo cuando el JSON no da una
        # version. El endpoint /dataset/{key}/document genera un EML nuevo y no
        # siempre conserva el packageId original, por lo que primero se consulta
        # el inventario de metadatos fuente.
        if (is.na(out$eml_version)) {
          metadata_docs <- .gbif_api_get_json(
            paste0("/dataset/", dataset_key, "/metadata")
          )

          eml_metadata <- Filter(
            function(metadata) {
              identical(as.character(.gbif_or(metadata$type, "")), "EML")
            },
            metadata_docs
          )

          # GBIF devuelve los documentos ordenados por prioridad; el primer EML
          # es por tanto el documento fuente preferente.
          if (length(eml_metadata) > 0L) {
            metadata_key <- as.character(
              .gbif_or(eml_metadata[[1]]$key, NA_character_)
            )

            if (!is.na(metadata_key) && nzchar(metadata_key)) {
              eml_doc <- .gbif_api_get_xml(
                paste0("/dataset/metadata/", metadata_key, "/document")
              )

              # Extraer packageId del nodo raiz del EML fuente.
              package_id <- xml2::xml_attr(
                xml2::xml_root(eml_doc),
                "packageId"
              )

              if (!is.na(package_id) && nzchar(package_id)) {
                out$eml_version <- .gbif_extract_version(package_id)
              }
            }
          }
        }

        pub_date <- trimws(as.character(.gbif_or(dataset$pubDate, NA_character_)))
        if (!is.na(pub_date) && nzchar(pub_date)) {
          out$eml_pub_date <- substr(pub_date, 1L, 10L)
        }

        gbif_count <- suppressWarnings(
          as.numeric(.gbif_or(occurrence$count, NA_real_))
        )
        if (!is.na(gbif_count)) {
          if (gbif_count > .Machine$integer.max) {
            stop("El conteo de GBIF excede el rango integer del output existente.")
          }
          out$eml_occurrences <- as.integer(gbif_count)
        }

        # El fallback se decide con el conteo obtenido en esta misma ejecucion,
        # antes de comparar o escribir metages_recurso_monitor.
        fallback_row_type <- .gbif_fallback_row_type(tipo_recurso_id)
        if (
          !is.na(gbif_count) &&
          identical(gbif_count, 0) &&
          !is.na(fallback_row_type)
        ) {
          # Desde que se activa el fallback, cualquier fallo debe invalidar el
          # cero provisional de GBIF, incluida la ausencia del endpoint.
          out$eml_occurrences <- NA_integer_
          dwca_endpoint <- .gbif_dwca_endpoint(dataset)
          out$eml_occurrences <- .gbif_count_dwca_row_type(
            dwca_url = dwca_endpoint,
            row_type = fallback_row_type
          )
        }

        out
      },
      error = function(e) {
        out$eml_status <- "error"
        out$eml_error_message <- conditionMessage(e)
        out
      }
    )
  }

  results <- vector("list", nrow(inputs_unique))

  for (i in seq_len(nrow(inputs_unique))) {
    if (isTRUE(progress)) {
      message(sprintf(
        "[%d/%d] Consultando GBIF: %s",
        i,
        nrow(inputs_unique),
        inputs_unique$dwca_url[i]
      ))
    }
    results[[i]] <- parse_one_input(
      input = inputs_unique$dwca_url[i],
      tipo_recurso_id = inputs_unique$tipo_recurso_id[i]
    )
    if (i < nrow(inputs_unique)) .gbif_sleep(request_delay)
  }

  metadata_df <- dplyr::bind_rows(results)

  if (has_resource_type) {
    dplyr::left_join(df, metadata_df, by = c("dwca_url", "tipo_recurso_id"))
  } else {
    metadata_df$tipo_recurso_id <- NULL
    dplyr::left_join(df, metadata_df, by = "dwca_url")
  }
}



#' Comparar snapshot nuevo con baseline de referencia
#'
#' @description
#' Compara un snapshot nuevo extraido desde GBIF, con los fallbacks necesarios
#' al DwC-A, contra el baseline incluido en `snapshot_df`.
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
.gbif_compare_resource_snapshot <- function(snapshot_df, checked_at = Sys.time()) {
  if (!"detected_dwca_url" %in% names(snapshot_df)) {
    snapshot_df$detected_dwca_url <- NA_character_
  }
  if (!"detected_eml_url" %in% names(snapshot_df)) {
    snapshot_df$detected_eml_url <- NA_character_
  }
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
      change_type = change_type,
      url_ipt_detected = detected_dwca_url,
      url_eml_detected = detected_eml_url
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
