.gbif_scalar <- function(x, default = NA_character_) {
  if (is.null(x) || length(x) == 0L || is.na(x[1])) {
    return(default)
  }
  as.character(x[1])
}


.gbif_parse_datetime <- function(x) {
  x <- .gbif_scalar(x)
  if (is.na(x) || !nzchar(trimws(x))) {
    return(as.POSIXct(NA, tz = "UTC"))
  }

  normalized <- trimws(x)
  normalized <- sub("[zZ]$", "+0000", normalized)
  normalized <- sub(
    "([+-][0-9]{2}):([0-9]{2})$",
    "\\1\\2",
    normalized
  )
  normalized <- sub(
    "\\.[0-9]+(?=([+-][0-9]{4})?$)",
    "",
    normalized,
    perl = TRUE
  )

  format <- if (grepl(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}$",
    normalized
  )) {
    "%Y-%m-%dT%H:%M:%S%z"
  } else if (grepl(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$",
    normalized
  )) {
    "%Y-%m-%dT%H:%M:%S"
  } else if (grepl(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$",
    normalized
  )) {
    "%Y-%m-%d %H:%M:%S"
  } else {
    return(as.POSIXct(NA, tz = "UTC"))
  }

  tryCatch(
    suppressWarnings(as.POSIXct(normalized, format = format, tz = "UTC")),
    error = function(e) as.POSIXct(NA, tz = "UTC")
  )
}


.gbif_parse_date <- function(x) {
  x <- .gbif_scalar(x)
  if (is.na(x) || !nzchar(x)) {
    return(as.Date(NA))
  }
  suppressWarnings(as.Date(substr(x, 1L, 10L)))
}


.gbif_paginate <- function(
    path,
    query = list(),
    page_limit = 300L,
    request_delay = 0.2
) {
  page_limit <- suppressWarnings(as.integer(page_limit[1]))
  if (is.na(page_limit) || page_limit < 1L || page_limit > 1000L) {
    stop("`page_limit` debe estar entre 1 y 1000.")
  }

  offset <- 0L
  pages <- list()

  repeat {
    response <- .gbif_api_get_json(
      path,
      query = c(query, list(limit = page_limit, offset = offset))
    )
    results <- .gbif_or(response$results, list())

    if (length(results) == 0L) {
      break
    }

    pages <- c(pages, results)
    offset <- offset + length(results)

    total <- suppressWarnings(as.integer(.gbif_or(response$count, NA_integer_)))
    end_of_records <- isTRUE(.gbif_or(response$endOfRecords, FALSE))
    if (end_of_records || (!is.na(total) && offset >= total)) {
      break
    }

    .gbif_sleep(request_delay)
  }

  pages
}


.gbif_extract_dataset_endpoints <- function(dataset) {
  endpoints <- .gbif_or(dataset$endpoints, list())
  endpoint_by_type <- function(type) {
    values <- vapply(endpoints, function(endpoint) {
      if (identical(.gbif_scalar(endpoint$type, ""), type)) {
        trimws(.gbif_scalar(endpoint$url))
      } else {
        NA_character_
      }
    }, character(1))
    values <- values[!is.na(values) & nzchar(values)]
    if (length(values) == 0L) NA_character_ else values[1]
  }

  list(
    dwca_url = endpoint_by_type("DWC_ARCHIVE"),
    eml_url = endpoint_by_type("EML")
  )
}


.gbif_fetch_dataset_details <- function(datasets, request_delay = 0.2) {
  if (length(datasets) == 0L) return(list())

  details <- vector("list", length(datasets))
  keys <- vapply(datasets, function(dataset) {
    tolower(.gbif_scalar(dataset$key))
  }, character(1))

  for (i in seq_along(datasets)) {
    if (is.na(keys[i]) || !nzchar(keys[i])) {
      stop("GBIF devolvi\u00F3 un dataset sin UUID en el inventario espa\u00F1ol.")
    }
    details[[i]] <- .gbif_api_get_json(paste0("/dataset/", keys[i]))
    if (i < length(datasets)) .gbif_sleep(request_delay)
  }

  names(details) <- keys
  details
}


.gbif_organization_rows <- function(organizations) {
  if (length(organizations) == 0L) {
    return(data.frame(
      publisher_key = character(),
      publisher_name = character(),
      publisher_country = character(),
      publisher_modified_at = as.POSIXct(character(), tz = "UTC"),
      stringsAsFactors = FALSE
    ))
  }

  dplyr::bind_rows(lapply(organizations, function(org) {
    data.frame(
      publisher_key = tolower(.gbif_scalar(org$key)),
      publisher_name = .gbif_scalar(org$title),
      publisher_country = toupper(.gbif_scalar(org$country)),
      publisher_modified_at = .gbif_parse_datetime(org$modified),
      stringsAsFactors = FALSE
    )
  }))
}


.gbif_dataset_rows <- function(datasets, publishers) {
  if (length(datasets) == 0L) {
    return(data.frame(
      gbif_dataset_uuid = character(),
      gbif_url = character(),
      dataset_title = character(),
      gbif_dataset_type = character(),
      gbif_modified_at = as.POSIXct(character(), tz = "UTC"),
      gbif_pub_date = as.Date(character()),
      gbif_version_registry = character(),
      publisher_key = character(),
      publisher_name = character(),
      publisher_country = character(),
      hosting_key = character(),
      hosting_name = character(),
      installation_key = character(),
      dwca_url = character(),
      eml_url = character(),
      stringsAsFactors = FALSE
    ))
  }

  rows <- dplyr::bind_rows(lapply(datasets, function(dataset) {
    endpoint_urls <- .gbif_extract_dataset_endpoints(dataset)

    key <- tolower(.gbif_scalar(dataset$key))
    data.frame(
      gbif_dataset_uuid = key,
      gbif_url = if (is.na(key)) NA_character_ else paste0(
        "https://www.gbif.org/dataset/", key
      ),
      dataset_title = .gbif_scalar(dataset$title),
      gbif_dataset_type = toupper(.gbif_scalar(dataset$type)),
      gbif_modified_at = .gbif_parse_datetime(dataset$modified),
      gbif_pub_date = .gbif_parse_date(dataset$pubDate),
      gbif_version_registry = .gbif_scalar(dataset$version),
      publisher_key = tolower(.gbif_scalar(dataset$publishingOrganizationKey)),
      publisher_name = .gbif_scalar(dataset$publishingOrganizationTitle),
      publisher_country = NA_character_,
      hosting_key = tolower(.gbif_scalar(dataset$hostingOrganizationKey)),
      hosting_name = .gbif_scalar(dataset$hostingOrganizationTitle),
      installation_key = tolower(.gbif_scalar(dataset$installationKey)),
      dwca_url = endpoint_urls$dwca_url,
      eml_url = endpoint_urls$eml_url,
      stringsAsFactors = FALSE
    )
  }))

  if (nrow(publishers) > 0L) {
    rows <- rows |>
      dplyr::left_join(
        publishers |>
          dplyr::select(
            publisher_key,
            publisher_name_registry = publisher_name,
            publisher_country_registry = publisher_country
          ),
        by = "publisher_key"
      ) |>
      dplyr::mutate(
        publisher_name = dplyr::coalesce(
          publisher_name_registry,
          publisher_name
        ),
        publisher_country = publisher_country_registry
      ) |>
      dplyr::select(-publisher_name_registry, -publisher_country_registry)
  }

  rows |>
    dplyr::filter(
      !is.na(gbif_dataset_uuid),
      nzchar(gbif_dataset_uuid)
    ) |>
    dplyr::distinct(gbif_dataset_uuid, .keep_all = TRUE)
}


#' Obtener el inventario de datasets publicados desde Espana en GBIF
#'
#' @description
#' Descarga publishers espanoles y datasets con `publishingCountry=ES`.
#' Consulta ademas el detalle de cada dataset para incluir sus endpoints
#' `DWC_ARCHIVE` y `EML`. Devuelve tablas normalizadas y respuestas detalladas
#' de GBIF, sin realizar escrituras ni requerir una conexion con MetaGES.
#'
#' @param page_limit Tamano de pagina usado en la API de GBIF.
#' @param request_delay Pausa en segundos entre paginas y bloques de consulta.
#'
#' @return Lista con `publishers`, `datasets`, `raw_publishers` y
#'   `raw_datasets`.
#'
#' @export
fetch_gbif_spain_inventory <- function(
    page_limit = 300L,
    request_delay = 0.2
) {
  organizations <- .gbif_paginate(
    "/organization",
    query = list(country = "ES", type = "PUBLISHER"),
    page_limit = page_limit,
    request_delay = request_delay
  )
  .gbif_sleep(request_delay)
  datasets <- .gbif_paginate(
    "/dataset/search",
    query = list(publishingCountry = "ES"),
    page_limit = page_limit,
    request_delay = request_delay
  )
  if (length(datasets) > 0L) .gbif_sleep(request_delay)
  datasets <- .gbif_fetch_dataset_details(
    datasets,
    request_delay = request_delay
  )

  publishers_df <- .gbif_organization_rows(organizations)
  datasets_df <- .gbif_dataset_rows(datasets, publishers_df)

  list(
    publishers = publishers_df,
    datasets = datasets_df,
    raw_publishers = organizations,
    raw_datasets = datasets
  )
}


.gbif_type_to_metages <- function(type) {
  mapping <- c(
    OCCURRENCE = 223L,
    SAMPLING_EVENT = 224L,
    CHECKLIST = 225L,
    METADATA = 226L
  )
  out <- unname(mapping[toupper(trimws(as.character(type)))])
  as.integer(out)
}


.gbif_safe_dataset_uuid <- function(x) {
  x <- trimws(.gbif_scalar(x))
  if (is.na(x) || !nzchar(x)) {
    return(NA_character_)
  }
  tryCatch(.gbif_dataset_uuid(x), error = function(e) NA_character_)
}


.gbif_resource_uuid <- function(uuid, gbif_url, ipt_url) {
  key <- .gbif_safe_dataset_uuid(uuid)
  if (is.na(key)) {
    key <- .gbif_safe_dataset_uuid(gbif_url)
  }
  if (is.na(key) && !is.na(.gbif_scalar(ipt_url))) {
    key <- .gbif_dataset_key_from_dwca(.gbif_scalar(ipt_url))
  }
  tolower(key)
}


.gbif_resource_uuids <- function(resources, request_delay = 0.2) {
  if (nrow(resources) == 0L) return(character())

  out <- rep(NA_character_, nrow(resources))
  resolution_errors <- rep(NA_character_, nrow(resources))
  needs_lookup <- vapply(seq_len(nrow(resources)), function(i) {
    is.na(.gbif_safe_dataset_uuid(resources$uuid[i])) &&
      is.na(.gbif_safe_dataset_uuid(resources$url_gbiforg[i])) &&
      !is.na(.gbif_scalar(resources$url_ipt[i])) &&
      nzchar(trimws(.gbif_scalar(resources$url_ipt[i])))
  }, logical(1))
  lookup_indices <- which(needs_lookup)

  for (i in seq_len(nrow(resources))) {
    out[i] <- tryCatch(
      .gbif_resource_uuid(
        resources$uuid[i],
        resources$url_gbiforg[i],
        resources$url_ipt[i]
      ),
      error = function(e) {
        resolution_errors[i] <<- conditionMessage(e)
        NA_character_
      }
    )
    if (i %in% lookup_indices && i != tail(lookup_indices, 1L)) {
      .gbif_sleep(request_delay)
    }
  }
  attr(out, "resolution_errors") <- resolution_errors
  out
}


.gbif_probe_dataset <- function(dataset_uuid) {
  tryCatch(
    {
      response <- .gbif_api_perform(
        paste0("/dataset/", dataset_uuid),
        accept_http_errors = TRUE
      )
      status <- httr2::resp_status(response)
      body <- if (status >= 200L && status < 300L) {
        httr2::resp_body_json(response, simplifyVector = FALSE)
      } else {
        NULL
      }
      list(status = status, body = body, error = NA_character_)
    },
    error = function(e) {
      list(status = NA_integer_, body = NULL, error = conditionMessage(e))
    }
  )
}


.gbif_is_due <- function(
    gbif_modified_at,
    last_checked_at,
    monitor_status,
    checked_at,
    max_stale_days = 30,
    force_full = FALSE
) {
  if (isTRUE(force_full)) {
    return(TRUE)
  }
  if (is.na(last_checked_at) || !identical(as.character(monitor_status), "ok")) {
    return(TRUE)
  }
  if (!is.na(gbif_modified_at) && gbif_modified_at > last_checked_at) {
    return(TRUE)
  }
  as.numeric(difftime(checked_at, last_checked_at, units = "days")) >=
    max_stale_days
}


.gbif_availability_transition <- function(
    probe,
    current_streak,
    resource_private,
    workflow_hidden,
    spanish_publisher_keys
) {
  current_streak <- suppressWarnings(as.integer(current_streak[1]))
  if (is.na(current_streak)) current_streak <- 0L
  resource_private <- isTRUE(as.integer(resource_private[1]) == 1L)
  workflow_hidden <- isTRUE(as.integer(workflow_hidden[1]) == 1L)

  if (is.na(probe$status)) {
    return(list(
      status = "error",
      streak = current_streak,
      action = "none",
      deleted_at = as.POSIXct(NA, tz = "UTC"),
      error = probe$error
    ))
  }

  if (probe$status %in% c(404L, 410L)) {
    streak <- current_streak + 1L
    return(list(
      status = "not_found",
      streak = streak,
      action = if (streak >= 3L && !resource_private) "review_private" else "none",
      deleted_at = as.POSIXct(NA, tz = "UTC"),
      error = NA_character_
    ))
  }

  if (probe$status < 200L || probe$status >= 300L || is.null(probe$body)) {
    return(list(
      status = "error",
      streak = current_streak,
      action = "none",
      deleted_at = as.POSIXct(NA, tz = "UTC"),
      error = paste("HTTP", probe$status)
    ))
  }

  deleted_at <- .gbif_parse_datetime(probe$body$deleted)
  if (!is.na(deleted_at)) {
    return(list(
      status = "deleted",
      streak = 0L,
      action = if (!resource_private) "review_private" else "none",
      deleted_at = deleted_at,
      error = NA_character_
    ))
  }

  publisher_key <- tolower(.gbif_scalar(
    probe$body$publishingOrganizationKey
  ))
  publishing_country <- toupper(.gbif_scalar(
    probe$body$publishingCountry
  ))
  is_spanish <- identical(publishing_country, "ES") ||
    publisher_key %in% spanish_publisher_keys
  if (!is_spanish) {
    return(list(
      status = "outside_spain",
      streak = 0L,
      action = if (resource_private && workflow_hidden) {
        "review_public"
      } else {
        "none"
      },
      deleted_at = as.POSIXct(NA, tz = "UTC"),
      error = NA_character_
    ))
  }

  list(
    status = "available",
    streak = 0L,
    action = if (resource_private && workflow_hidden) "review_public" else "none",
    deleted_at = as.POSIXct(NA, tz = "UTC"),
    error = NA_character_
  )
}


.gbif_load_metages_resources <- function(con) {
  DBI::dbGetQuery(con, "
SELECT
    r.recurso_id AS recurso_fk,
    r.uuid,
    r.url_gbiforg,
    r.url_ipt,
    r.url_eml,
    r.private,
    r.Tipo_recurso AS tipo_recurso_id,
    mt.name AS tipo_recurso,
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
    ) AS baseline_version,
    m.last_checked_at,
    m.monitor_status,
    m.gbif_availability_status,
    m.gbif_not_found_streak,
    m.visibility_action,
    m.visibility_applied_by_workflow
FROM metages_recurso r
LEFT JOIN metages_types mt
  ON mt.types_id = r.Tipo_recurso
LEFT JOIN metages_recurso_monitor m
  ON m.recurso_fk = r.recurso_id
LEFT JOIN metages_provision_recurso p
  ON p.provision_id = (
      SELECT MAX(p2.provision_id)
      FROM metages_provision_recurso p2
      WHERE p2.recurso_fk = r.recurso_id
  )
WHERE COALESCE(
    NULLIF(TRIM(r.uuid), ''),
    NULLIF(TRIM(r.url_gbiforg), ''),
    NULLIF(TRIM(r.url_ipt), '')
) IS NOT NULL
") |>
    tibble::as_tibble()
}


.gbif_resource_match_index <- function(resources) {
  resources |>
    dplyr::filter(
      !is.na(gbif_dataset_uuid),
      nzchar(gbif_dataset_uuid)
    ) |>
    dplyr::mutate(
      is_public = !is.na(private) & private == 0L,
      is_private = !is_public,
      is_workflow_hidden = is_private &
        !is.na(visibility_applied_by_workflow) &
        visibility_applied_by_workflow == 1L
    ) |>
    dplyr::group_by(gbif_dataset_uuid) |>
    dplyr::summarise(
      metages_matches = dplyr::n(),
      metages_public_matches = sum(is_public),
      metages_private_matches = sum(is_private),
      metages_workflow_hidden_matches = sum(is_workflow_hidden),
      public_recurso_fks = paste(
        sort(unique(recurso_fk[is_public])),
        collapse = ","
      ),
      .groups = "drop"
    )
}


.gbif_reconcile_new_candidates <- function(con, existing_uuids) {
  existing_uuids <- unique(tolower(trimws(existing_uuids)))
  existing_uuids <- existing_uuids[
    !is.na(existing_uuids) & nzchar(existing_uuids)
  ]
  if (length(existing_uuids) == 0L) return(invisible(0L))

  deleted <- 0L
  sql <- "
DELETE FROM metages_recurso_monitor_nuevos
WHERE incorporated_recurso_fk IS NULL
  AND LOWER(TRIM(gbif_dataset_uuid)) = ?
"
  for (dataset_uuid in existing_uuids) {
    deleted <- deleted + DBI::dbExecute(con, sql, params = list(dataset_uuid))
  }
  invisible(deleted)
}


.gbif_upsert_new_candidates <- function(con, candidates, checked_at) {
  if (nrow(candidates) == 0L) return(invisible(0L))

  sql <- "
INSERT INTO metages_recurso_monitor_nuevos (
    gbif_dataset_uuid, gbif_url, dwca_url, eml_url, dataset_title,
    gbif_dataset_type, tipo_recurso_fk, gbif_modified_at, gbif_pub_date,
    gbif_version, gbif_records, publisher_key, publisher_name,
    publisher_country, hosting_key, hosting_name, installation_key,
    match_status, extraction_status, extraction_error,
    first_seen_at, last_seen_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
    review_notes = CASE
        WHEN review_status = 'approved' AND (
            NOT (match_status <=> VALUES(match_status))
            OR NOT (extraction_status <=> VALUES(extraction_status))
            OR NOT (dataset_title <=> VALUES(dataset_title))
            OR NOT (tipo_recurso_fk <=> VALUES(tipo_recurso_fk))
            OR NOT (gbif_pub_date <=> VALUES(gbif_pub_date))
            OR NOT (gbif_version <=> VALUES(gbif_version))
            OR NOT (gbif_records <=> VALUES(gbif_records))
            OR NOT (gbif_url <=> VALUES(gbif_url))
            OR NOT (dwca_url <=> VALUES(dwca_url))
            OR NOT (eml_url <=> VALUES(eml_url))
        ) THEN 'Aprobaci\u00F3n revocada: GBIF cambi\u00F3 datos incorporables.'
        ELSE review_notes
    END,
    reviewed_at = CASE
        WHEN review_status = 'approved' AND (
            NOT (match_status <=> VALUES(match_status))
            OR NOT (extraction_status <=> VALUES(extraction_status))
            OR NOT (dataset_title <=> VALUES(dataset_title))
            OR NOT (tipo_recurso_fk <=> VALUES(tipo_recurso_fk))
            OR NOT (gbif_pub_date <=> VALUES(gbif_pub_date))
            OR NOT (gbif_version <=> VALUES(gbif_version))
            OR NOT (gbif_records <=> VALUES(gbif_records))
            OR NOT (gbif_url <=> VALUES(gbif_url))
            OR NOT (dwca_url <=> VALUES(dwca_url))
            OR NOT (eml_url <=> VALUES(eml_url))
        ) THEN NULL ELSE reviewed_at
    END,
    reviewed_by = CASE
        WHEN review_status = 'approved' AND (
            NOT (match_status <=> VALUES(match_status))
            OR NOT (extraction_status <=> VALUES(extraction_status))
            OR NOT (dataset_title <=> VALUES(dataset_title))
            OR NOT (tipo_recurso_fk <=> VALUES(tipo_recurso_fk))
            OR NOT (gbif_pub_date <=> VALUES(gbif_pub_date))
            OR NOT (gbif_version <=> VALUES(gbif_version))
            OR NOT (gbif_records <=> VALUES(gbif_records))
            OR NOT (gbif_url <=> VALUES(gbif_url))
            OR NOT (dwca_url <=> VALUES(dwca_url))
            OR NOT (eml_url <=> VALUES(eml_url))
        ) THEN NULL ELSE reviewed_by
    END,
    review_status = CASE
        WHEN review_status = 'approved' AND (
            NOT (match_status <=> VALUES(match_status))
            OR NOT (extraction_status <=> VALUES(extraction_status))
            OR NOT (dataset_title <=> VALUES(dataset_title))
            OR NOT (tipo_recurso_fk <=> VALUES(tipo_recurso_fk))
            OR NOT (gbif_pub_date <=> VALUES(gbif_pub_date))
            OR NOT (gbif_version <=> VALUES(gbif_version))
            OR NOT (gbif_records <=> VALUES(gbif_records))
            OR NOT (gbif_url <=> VALUES(gbif_url))
            OR NOT (dwca_url <=> VALUES(dwca_url))
            OR NOT (eml_url <=> VALUES(eml_url))
        ) THEN 'pending' ELSE review_status
    END,
    gbif_url = VALUES(gbif_url),
    dwca_url = VALUES(dwca_url),
    eml_url = VALUES(eml_url),
    dataset_title = VALUES(dataset_title),
    gbif_dataset_type = VALUES(gbif_dataset_type),
    tipo_recurso_fk = VALUES(tipo_recurso_fk),
    gbif_modified_at = VALUES(gbif_modified_at),
    gbif_pub_date = VALUES(gbif_pub_date),
    gbif_version = VALUES(gbif_version),
    gbif_records = VALUES(gbif_records),
    publisher_key = VALUES(publisher_key),
    publisher_name = VALUES(publisher_name),
    publisher_country = VALUES(publisher_country),
    hosting_key = VALUES(hosting_key),
    hosting_name = VALUES(hosting_name),
    installation_key = VALUES(installation_key),
    match_status = VALUES(match_status),
    extraction_status = VALUES(extraction_status),
    extraction_error = VALUES(extraction_error),
    last_seen_at = VALUES(last_seen_at),
    updated_when = CURRENT_TIMESTAMP
"

  for (i in seq_len(nrow(candidates))) {
    row <- candidates[i, ]
    DBI::dbExecute(con, sql, params = list(
      row$gbif_dataset_uuid,
      row$gbif_url,
      row$dwca_url,
      row$eml_url,
      row$dataset_title,
      row$gbif_dataset_type,
      row$tipo_recurso_fk,
      row$gbif_modified_at,
      row$gbif_pub_date,
      row$gbif_version,
      row$gbif_records,
      row$publisher_key,
      row$publisher_name,
      row$publisher_country,
      row$hosting_key,
      row$hosting_name,
      row$installation_key,
      row$match_status,
      row$extraction_status,
      row$extraction_error,
      checked_at,
      checked_at
    ))
  }
  invisible(nrow(candidates))
}


.gbif_upsert_monitor_content <- function(con, current_df) {
  if (nrow(current_df) == 0L) return(invisible(0L))
  sql <- "
INSERT INTO metages_recurso_monitor (
    recurso_fk, tipo_recurso, last_checked_at, last_change_at,
    eml_title_detected, previous_eml_title_detected,
    eml_version_detected, previous_eml_version_detected,
    eml_pub_date_detected, previous_eml_pub_date_detected,
    occurrences_detected, previous_occurrences_detected,
    occurrences_diff_last_check, monitor_status, monitor_error_message,
    change_flag, change_type, url_ipt_detected, url_eml_detected
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
    url_ipt_detected = VALUES(url_ipt_detected),
    url_eml_detected = VALUES(url_eml_detected),
    updated_when = CURRENT_TIMESTAMP
"
  for (i in seq_len(nrow(current_df))) {
    DBI::dbExecute(con, sql, params = as.list(current_df[i, ]))
  }
  invisible(nrow(current_df))
}


.gbif_upsert_monitor_endpoints <- function(con, endpoints) {
  if (nrow(endpoints) == 0L) return(invisible(0L))
  sql <- "
INSERT INTO metages_recurso_monitor (
    recurso_fk, tipo_recurso, url_ipt_detected, url_eml_detected
) VALUES (?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
    tipo_recurso = COALESCE(VALUES(tipo_recurso), tipo_recurso),
    url_ipt_detected = VALUES(url_ipt_detected),
    url_eml_detected = VALUES(url_eml_detected),
    updated_when = CURRENT_TIMESTAMP
"
  for (i in seq_len(nrow(endpoints))) {
    DBI::dbExecute(con, sql, params = as.list(endpoints[i, ]))
  }
  invisible(nrow(endpoints))
}


.gbif_upsert_availability <- function(con, availability, checked_at) {
  if (nrow(availability) == 0L) return(invisible(0L))
  sql <- "
INSERT INTO metages_recurso_monitor (
    recurso_fk, tipo_recurso, gbif_availability_status,
    gbif_availability_checked_at, gbif_deleted_at,
    gbif_not_found_streak, visibility_action, visibility_action_at,
    monitor_status, monitor_error_message
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
ON DUPLICATE KEY UPDATE
    tipo_recurso = COALESCE(VALUES(tipo_recurso), tipo_recurso),
    gbif_availability_status = VALUES(gbif_availability_status),
    gbif_availability_checked_at = VALUES(gbif_availability_checked_at),
    gbif_deleted_at = VALUES(gbif_deleted_at),
    gbif_not_found_streak = VALUES(gbif_not_found_streak),
    visibility_action = CASE
        WHEN VALUES(visibility_action) = 'none'
         AND visibility_action IN ('private_applied', 'public_applied')
        THEN visibility_action
        ELSE VALUES(visibility_action)
    END,
    visibility_action_at = CASE
        WHEN VALUES(visibility_action) = 'none' THEN visibility_action_at
        ELSE VALUES(visibility_action_at)
    END,
    monitor_error_message = COALESCE(VALUES(monitor_error_message), monitor_error_message),
    updated_when = CURRENT_TIMESTAMP
"

  for (i in seq_len(nrow(availability))) {
    row <- availability[i, ]
    DBI::dbExecute(con, sql, params = list(
      row$recurso_fk,
      row$tipo_recurso,
      row$gbif_availability_status,
      checked_at,
      row$gbif_deleted_at,
      row$gbif_not_found_streak,
      row$visibility_action,
      if (identical(as.character(row$visibility_action[[1]]), "none")) {
        as.POSIXct(NA, tz = "UTC")
      } else {
        checked_at
      },
      row$monitor_error_message
    ))
  }
  invisible(nrow(availability))
}


.gbif_insert_monitor_log <- function(con, log_df) {
  if (nrow(log_df) == 0L) return(invisible(0L))
  sql <- "
INSERT INTO metages_recurso_monitor_log (
    recurso_fk, tipo_recurso, event_at, event_type,
    previous_eml_title_detected, new_eml_title_detected,
    previous_eml_version_detected, new_eml_version_detected,
    previous_eml_pub_date_detected, new_eml_pub_date_detected,
    previous_occurrences_detected, new_occurrences_detected,
    occurrences_diff, previous_monitor_status, new_monitor_status,
    monitor_error_message
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
"
  for (i in seq_len(nrow(log_df))) {
    DBI::dbExecute(con, sql, params = as.list(log_df[i, ]))
  }
  invisible(nrow(log_df))
}


#' Sincronizar GBIF con los monitores MetaGES
#'
#' @description
#' Descubre datasets publicados desde Espana, los compara por UUID con MetaGES
#' y prepara recursos nuevos. Tambien mantiene todos los recursos publicos de
#' MetaGES vinculados con GBIF, incluidos los publicados fuera de Espana.
#'
#' Reutiliza el extractor detallado interno como unica implementacion para
#' titulo, version, fecha, conteo y fallback DwC-A. La funcion nunca incorpora
#' recursos ni aplica cambios definitivos sobre `metages_recurso`; esas
#' acciones pertenecen a los procedimientos SQL controlados.
#'
#' @param con Conexion DBI existente. Si es `NULL`, se abre una conexion con
#'   [conectar_metages()] y se cierra al terminar el workflow completo.
#' @param entorno Entorno usado cuando `con` es `NULL`: `"prod"` o `"test"`.
#' @param progress Mostrar mensajes de progreso.
#' @param request_delay Pausa en segundos entre paginas o comprobaciones GBIF.
#' @param max_stale_days Antiguedad maxima de un chequeo detallado antes de
#'   forzar una reconciliacion.
#' @param force_full Si es `TRUE`, vuelve a extraer todos los recursos publicos
#'   resolubles y disponibles, sean o no espanoles.
#' @param write Si es `FALSE`, ejecuta la lectura y comparacion sin escribir
#'   en los monitores. Combinado con `force_full=TRUE` sustituye la comparacion
#'   manual completa anterior.
#' @param checked_at Fecha-hora UTC del run.
#'
#' @return Invisiblemente, lista con inventario normalizado y crudo, resumen,
#'   correspondencias, candidatos, recursos sin identidad GBIF resoluble,
#'   errores de identidad, comparaciones y disponibilidad. `datasets` parte del
#'   inventario externo espanol y separa
#'   sus coincidencias publicas y privadas en MetaGES. `new_candidates`
#'   contiene exclusivamente datasets externos sin ninguna coincidencia
#'   interna. `identity_errors` parte de UUID usados por dos o mas recursos
#'   publicos de MetaGES y se enriquece con el dataset externo espanol cuando
#'   existe. `existing_checked` y `existing_skipped` representan recursos
#'   publicos de MetaGES con una correspondencia externa unica.
#'   `endpoint_monitor` contiene los endpoints detectados que se preparan para
#'   completar campos internos vacios.
#'   `unresolved_resources` contiene recursos MetaGES que se excluyeron porque
#'   no pudo obtenerse un UUID desde `uuid`, `url_gbiforg` ni `url_ipt`.
#'
#' @details
#' Los recursos que solo coinciden con filas privadas se clasifican como
#' `existing_private` y nunca se tratan como altas. Los privados manualmente
#' quedan fuera del seguimiento de disponibilidad; los privatizados por este
#' workflow si se conservan en `availability` para detectar su reaparicion.
#' Los endpoints GBIF detectados se preparan para completar `url_ipt` y
#' `url_eml` unicamente cuando esos campos estan vacios; nunca se sustituyen ni
#' se borran URLs existentes.
#' Con `write = TRUE`, antes de escribir nuevos candidatos se retiran del
#' staging las filas no incorporadas cuyo UUID ya exista en MetaGES.
#'
#' @export
run_gbif_spain_workflow <- function(
    con = NULL,
    entorno = c("prod", "test"),
    progress = TRUE,
    request_delay = 0.2,
    max_stale_days = 30,
    force_full = FALSE,
    write = TRUE,
    checked_at = Sys.time()
) {
  entorno <- match.arg(entorno)
  max_stale_days <- suppressWarnings(as.numeric(max_stale_days[1]))
  if (is.na(max_stale_days) || max_stale_days <= 0) {
    stop("`max_stale_days` debe ser mayor que cero.")
  }
  if (!is.logical(write) || length(write) != 1L || is.na(write)) {
    stop("`write` debe ser TRUE o FALSE.")
  }
  checked_at <- as.POSIXct(checked_at, tz = "UTC")

  owns_connection <- is.null(con)
  connection_bundle <- NULL
  if (owns_connection) {
    connection_bundle <- conectar_metages(entorno = entorno)
    con <- connection_bundle$con
    on.exit({
      try(DBI::dbDisconnect(con), silent = TRUE)
      tunnel <- connection_bundle$tunnel
      if (!is.null(tunnel)) try(tunnel$kill(), silent = TRUE)
      ssh_session <- connection_bundle$ssh
      if (!is.null(ssh_session)) {
        try(ssh::ssh_disconnect(ssh_session), silent = TRUE)
      }
    }, add = TRUE)
  }

  if (isTRUE(progress)) message("Descargando inventario GBIF Espa\u00F1a...")
  inventory <- fetch_gbif_spain_inventory(request_delay = request_delay)
  resources <- .gbif_load_metages_resources(con)

  resolved_uuids <- .gbif_resource_uuids(
    resources,
    request_delay = request_delay
  )
  resources$gbif_dataset_uuid <- as.character(resolved_uuids)
  resolution_errors <- attr(resolved_uuids, "resolution_errors")
  if (is.null(resolution_errors)) {
    resolution_errors <- rep(NA_character_, nrow(resources))
  }
  resources$gbif_uuid_resolution_error <- resolution_errors
  unresolved_resources <- resources |>
    dplyr::filter(is.na(gbif_dataset_uuid) | !nzchar(gbif_dataset_uuid)) |>
    dplyr::mutate(
      workflow_exclusion_reason = dplyr::case_when(
        !is.na(gbif_uuid_resolution_error) &
          nzchar(gbif_uuid_resolution_error) ~
          paste0("No se pudo resolver el UUID GBIF: ",
                 gbif_uuid_resolution_error),
        TRUE ~ paste(
          "No hay un UUID GBIF v\u00E1lido en uuid o url_gbiforg",
          "y url_ipt no permiti\u00F3 resolverlo."
        )
      )
    )
  if (nrow(unresolved_resources) > 0L && isTRUE(progress)) {
    message(sprintf(
      "Excluyendo %d recurso(s) MetaGES sin UUID GBIF resoluble.",
      nrow(unresolved_resources)
    ))
  }

  resource_counts <- .gbif_resource_match_index(resources)

  datasets <- inventory$datasets |>
    dplyr::left_join(resource_counts, by = "gbif_dataset_uuid") |>
    dplyr::mutate(
      metages_matches = dplyr::coalesce(metages_matches, 0L),
      metages_public_matches = dplyr::coalesce(
        metages_public_matches,
        0L
      ),
      metages_private_matches = dplyr::coalesce(
        metages_private_matches,
        0L
      ),
      metages_workflow_hidden_matches = dplyr::coalesce(
        metages_workflow_hidden_matches,
        0L
      ),
      public_recurso_fks = dplyr::coalesce(public_recurso_fks, ""),
      match_status = dplyr::case_when(
        metages_public_matches >= 2L ~ "identity_error",
        metages_public_matches == 1L ~ "existing",
        metages_matches >= 1L ~ "existing_private",
        TRUE ~ "missing"
      ),
      tipo_recurso_fk = .gbif_type_to_metages(gbif_dataset_type),
      inventory_scope = "spain"
    )

  public_resources <- resources |>
    dplyr::filter(!is.na(private), private == 0L)
  workflow_hidden_resources <- resources |>
    dplyr::filter(
      !is.na(private),
      private == 1L,
      !is.na(visibility_applied_by_workflow),
      visibility_applied_by_workflow == 1L
    )

  spanish_existing <- datasets |>
    dplyr::filter(match_status == "existing") |>
    dplyr::inner_join(
      public_resources,
      by = "gbif_dataset_uuid",
      suffix = c("_gbif", "_metages")
    )

  spanish_workflow_hidden <- datasets |>
    dplyr::filter(
      match_status != "identity_error",
      metages_public_matches == 0L,
      metages_workflow_hidden_matches > 0L
    ) |>
    dplyr::inner_join(
      workflow_hidden_resources,
      by = "gbif_dataset_uuid",
      suffix = c("_gbif", "_metages")
    )

  identity_errors <- resource_counts |>
    dplyr::filter(metages_public_matches >= 2L) |>
    dplyr::left_join(inventory$datasets, by = "gbif_dataset_uuid") |>
    dplyr::mutate(
      match_status = "identity_error",
      in_gbif_spain_inventory = !is.na(gbif_url)
    )

  inventory_ids <- datasets$gbif_dataset_uuid
  identity_error_ids <- identity_errors$gbif_dataset_uuid
  missing_resources <- resources |>
    dplyr::left_join(
      resource_counts |>
        dplyr::select(
          gbif_dataset_uuid,
          metages_public_matches
        ),
      by = "gbif_dataset_uuid"
    ) |>
    dplyr::filter(
      !is.na(gbif_dataset_uuid),
      nzchar(gbif_dataset_uuid),
      !gbif_dataset_uuid %in% inventory_ids,
      !gbif_dataset_uuid %in% identity_error_ids,
      (!is.na(private) & private == 0L) |
        (
          !is.na(private) & private == 1L &
            !is.na(visibility_applied_by_workflow) &
            visibility_applied_by_workflow == 1L &
            dplyr::coalesce(metages_public_matches, 0L) == 0L
        )
    )

  spanish_publisher_keys <- inventory$publishers$publisher_key
  probed_availability <- vector("list", nrow(missing_resources))
  probed_dataset_rows <- vector("list", nrow(missing_resources))
  probed_dataset_details <- vector("list", nrow(missing_resources))
  if (nrow(missing_resources) > 0L && isTRUE(progress)) {
    message("Comprobando recursos MetaGES ausentes del inventario espa\u00F1ol...")
  }

  for (i in seq_len(nrow(missing_resources))) {
    probe <- .gbif_probe_dataset(missing_resources$gbif_dataset_uuid[i])
    transition <- .gbif_availability_transition(
      probe = probe,
      current_streak = missing_resources$gbif_not_found_streak[i],
      resource_private = missing_resources$private[i],
      workflow_hidden = missing_resources$visibility_applied_by_workflow[i],
      spanish_publisher_keys = spanish_publisher_keys
    )
    probed_availability[[i]] <- data.frame(
      recurso_fk = missing_resources$recurso_fk[i],
      tipo_recurso = missing_resources$tipo_recurso[i],
      gbif_availability_status = transition$status,
      gbif_deleted_at = transition$deleted_at,
      gbif_not_found_streak = transition$streak,
      visibility_action = transition$action,
      monitor_error_message = transition$error,
      stringsAsFactors = FALSE
    )

    if (
      transition$status %in% c("available", "outside_spain") &&
      !is.null(probe$body)
    ) {
      probed_dataset_details[[i]] <- probe$body
      probed_dataset_rows[[i]] <- .gbif_dataset_rows(
        list(probe$body),
        inventory$publishers
      ) |>
        dplyr::mutate(
          metages_matches = 1L,
          match_status = "existing",
          tipo_recurso_fk = .gbif_type_to_metages(gbif_dataset_type),
          inventory_scope = "outside_inventory"
        )
    }

    if (i < nrow(missing_resources)) .gbif_sleep(request_delay)
  }

  probed_datasets <- dplyr::bind_rows(probed_dataset_rows)
  if (nrow(probed_datasets) == 0L) {
    probed_datasets <- datasets[0, ]
  } else {
    probed_datasets <- probed_datasets |>
      dplyr::distinct(gbif_dataset_uuid, .keep_all = TRUE)
  }
  probed_existing <- probed_datasets |>
    dplyr::inner_join(
      public_resources,
      by = "gbif_dataset_uuid",
      suffix = c("_gbif", "_metages")
    )

  existing <- dplyr::bind_rows(spanish_existing, probed_existing) |>
    dplyr::distinct(recurso_fk, .keep_all = TRUE)

  if (nrow(existing) > 0L) {
    existing$due <- mapply(
      .gbif_is_due,
      existing$gbif_modified_at,
      as.POSIXct(existing$last_checked_at, tz = "UTC"),
      existing$monitor_status,
      MoreArgs = list(
        checked_at = checked_at,
        max_stale_days = max_stale_days,
        force_full = force_full
      ),
      USE.NAMES = FALSE
    )
    existing$due <- existing$due &
      !is.na(existing$private) & existing$private == 0L
  } else {
    existing$due <- logical()
  }

  new_rows <- datasets |>
    dplyr::filter(match_status == "missing")
  extractable_new <- new_rows |>
    dplyr::filter(!is.na(tipo_recurso_fk)) |>
    dplyr::transmute(
      source_kind = "new",
      gbif_dataset_uuid,
      recurso_fk = NA_integer_,
      tipo_recurso_id = tipo_recurso_fk,
      tipo_recurso = gbif_dataset_type,
      dwca_url = gbif_dataset_uuid,
      baseline_title = NA_character_,
      baseline_reference_date = NA_character_,
      baseline_occurrences = NA_real_,
      baseline_version = NA_character_
    )
  extractable_existing <- existing |>
    dplyr::filter(due) |>
    dplyr::transmute(
      source_kind = "existing",
      gbif_dataset_uuid,
      recurso_fk,
      tipo_recurso_id,
      tipo_recurso,
      dwca_url = gbif_dataset_uuid,
      baseline_title,
      baseline_reference_date,
      baseline_occurrences = suppressWarnings(as.numeric(baseline_occurrences)),
      baseline_version
    )

  extraction_input <- dplyr::bind_rows(
    extractable_new,
    extractable_existing
  )
  dataset_details <- c(
    inventory$raw_datasets,
    Filter(Negate(is.null), probed_dataset_details)
  )
  if (length(dataset_details) > 0L) {
    names(dataset_details) <- vapply(dataset_details, function(dataset) {
      tolower(.gbif_scalar(dataset$key))
    }, character(1))
    dataset_details <- dataset_details[!duplicated(names(dataset_details))]
  }
  extraction <- if (nrow(extraction_input) > 0L) {
    .gbif_extract_dataset_metadata(
      extraction_input,
      progress = progress,
      request_delay = request_delay,
      dataset_details = dataset_details
    )
  } else {
    extraction_input |>
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
  }
  if (!"detected_dwca_url" %in% names(extraction)) {
    extraction$detected_dwca_url <- NA_character_
  }
  if (!"detected_eml_url" %in% names(extraction)) {
    extraction$detected_eml_url <- NA_character_
  }

  new_metadata <- extraction |>
    dplyr::filter(source_kind == "new") |>
    dplyr::select(
      gbif_dataset_uuid,
      eml_title,
      eml_version,
      eml_pub_date,
      eml_occurrences,
      detected_dwca_url,
      detected_eml_url,
      eml_status,
      eml_error_message
    )
  candidates <- new_rows |>
    dplyr::left_join(new_metadata, by = "gbif_dataset_uuid") |>
    dplyr::mutate(
      dataset_title = dplyr::coalesce(eml_title, dataset_title),
      gbif_version = dplyr::coalesce(eml_version, gbif_version_registry),
      gbif_pub_date = dplyr::coalesce(
        suppressWarnings(as.Date(eml_pub_date)),
        gbif_pub_date
      ),
      gbif_records = suppressWarnings(as.numeric(eml_occurrences)),
      dwca_url = dplyr::coalesce(detected_dwca_url, dwca_url),
      eml_url = dplyr::coalesce(detected_eml_url, eml_url),
      extraction_status = dplyr::case_when(
        is.na(tipo_recurso_fk) ~ "blocked",
        is.na(eml_status) ~ "error",
        TRUE ~ eml_status
      ),
      extraction_error = dplyr::case_when(
        is.na(tipo_recurso_fk) ~ "Tipo GBIF sin mapeo MetaGES.",
        TRUE ~ eml_error_message
      )
    )

  existing_snapshot <- extraction |>
    dplyr::filter(source_kind == "existing")
  comparison <- if (nrow(existing_snapshot) > 0L) {
    .gbif_compare_resource_snapshot(
      existing_snapshot,
      checked_at = checked_at
    )
  } else {
    list(
      current_upsert_df = data.frame(),
      log_insert_df = data.frame(),
      comparison_df = data.frame()
    )
  }

  active_availability <- dplyr::bind_rows(
    spanish_existing,
    spanish_workflow_hidden
  ) |>
    dplyr::transmute(
      recurso_fk,
      tipo_recurso,
      gbif_availability_status = "available",
      gbif_deleted_at = as.POSIXct(NA, tz = "UTC"),
      gbif_not_found_streak = 0L,
      visibility_action = dplyr::case_when(
        private == 1L & visibility_applied_by_workflow == 1L ~ "review_public",
        TRUE ~ "none"
      ),
      monitor_error_message = NA_character_
    )
  availability <- dplyr::bind_rows(
    active_availability,
    dplyr::bind_rows(probed_availability)
  )

  detailed_comparison <- comparison$comparison_df
  endpoint_monitor <- existing |>
    dplyr::transmute(
      recurso_fk,
      tipo_recurso,
      url_ipt_detected = dwca_url,
      url_eml_detected = eml_url
    ) |>
    dplyr::filter(
      (!is.na(url_ipt_detected) & nzchar(url_ipt_detected)) |
        (!is.na(url_eml_detected) & nzchar(url_eml_detected))
    )
  summary <- tibble::tibble(
    metric = c(
      "publishers_gbif_spain",
      "datasets_gbif_spain",
      "metages_resources_with_gbif_uuid",
      "metages_resources_without_resolvable_gbif_uuid",
      "datasets_missing",
      "datasets_existing",
      "datasets_existing_private",
      "datasets_identity_errors",
      "existing_checked",
      "existing_checked_outside_inventory",
      "titles_different",
      "record_counts_different",
      "review_private",
      "review_public"
    ),
    value = c(
      nrow(inventory$publishers),
      nrow(datasets),
      sum(!is.na(resources$gbif_dataset_uuid)),
      nrow(unresolved_resources),
      sum(datasets$match_status == "missing"),
      sum(datasets$match_status == "existing"),
      sum(datasets$match_status == "existing_private"),
      sum(datasets$match_status == "identity_error"),
      sum(existing$due, na.rm = TRUE),
      sum(
        existing$due & existing$inventory_scope == "outside_inventory",
        na.rm = TRUE
      ),
      if (nrow(detailed_comparison) == 0L) 0L else
        sum(detailed_comparison$title_changed, na.rm = TRUE),
      if (nrow(detailed_comparison) == 0L) 0L else
        sum(detailed_comparison$occurrences_changed, na.rm = TRUE),
      sum(availability$visibility_action == "review_private", na.rm = TRUE),
      sum(availability$visibility_action == "review_public", na.rm = TRUE)
    )
  )

  if (isTRUE(write)) {
    DBI::dbBegin(con)
    tryCatch(
      {
        .gbif_reconcile_new_candidates(
          con,
          resources$gbif_dataset_uuid
        )
        .gbif_upsert_new_candidates(con, candidates, checked_at)
        .gbif_upsert_monitor_content(con, comparison$current_upsert_df)
        .gbif_upsert_monitor_endpoints(con, endpoint_monitor)
        .gbif_insert_monitor_log(con, comparison$log_insert_df)
        .gbif_upsert_availability(con, availability, checked_at)
        DBI::dbCommit(con)
      },
      error = function(e) {
        DBI::dbRollback(con)
        stop(e)
      }
    )
  }

  invisible(list(
    summary = summary,
    write = write,
    publishers = inventory$publishers,
    datasets = datasets,
    raw_publishers = inventory$raw_publishers,
    raw_datasets = inventory$raw_datasets,
    metages_resources = resources,
    unresolved_resources = unresolved_resources,
    new_candidates = candidates,
    identity_errors = identity_errors,
    existing_checked = existing |>
      dplyr::filter(due),
    existing_skipped = existing |>
      dplyr::filter(!due),
    probed_datasets = probed_datasets,
    extraction = extraction,
    comparison = comparison$comparison_df,
    monitor_upsert = comparison$current_upsert_df,
    endpoint_monitor = endpoint_monitor,
    monitor_log = comparison$log_insert_df,
    availability = availability
  ))
}
