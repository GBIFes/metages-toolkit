testthat::test_that("los tipos GBIF usan el mapeo acordado", {
  testthat::expect_equal(
    metagesToolkit:::.gbif_type_to_metages(c(
      "OCCURRENCE", "SAMPLING_EVENT", "CHECKLIST", "METADATA", "OTHER"
    )),
    c(223L, 224L, 225L, 226L, NA_integer_)
  )
})

testthat::test_that("las fechas ISO-8601 de GBIF se convierten a UTC", {
  parse_datetime <- metagesToolkit:::.gbif_parse_datetime

  testthat::expect_equal(
    parse_datetime("2017-02-06T15:01:54.004+00:00"),
    as.POSIXct("2017-02-06 15:01:54", tz = "UTC")
  )
  testthat::expect_equal(
    parse_datetime("2026-08-20T10:00:00Z"),
    as.POSIXct("2026-08-20 10:00:00", tz = "UTC")
  )
  testthat::expect_equal(
    parse_datetime("2026-08-20T10:00:00.123+02:00"),
    as.POSIXct("2026-08-20 08:00:00", tz = "UTC")
  )
  testthat::expect_equal(
    parse_datetime("2026-08-20T10:00:00.123-03:30"),
    as.POSIXct("2026-08-20 13:30:00", tz = "UTC")
  )
  testthat::expect_equal(
    parse_datetime("2026-08-20T10:00:00"),
    as.POSIXct("2026-08-20 10:00:00", tz = "UTC")
  )
  testthat::expect_equal(
    parse_datetime("2026-08-20 10:00:00"),
    as.POSIXct("2026-08-20 10:00:00", tz = "UTC")
  )
})

testthat::test_that("las fechas GBIF vacías o inválidas devuelven NA POSIXct", {
  parse_datetime <- metagesToolkit:::.gbif_parse_datetime

  for (value in list(NULL, "", "   ", NA_character_, "fecha-invalida")) {
    parsed <- testthat::expect_no_error(parse_datetime(value))
    testthat::expect_s3_class(parsed, "POSIXct")
    testthat::expect_true(is.na(parsed))
  }
})

testthat::test_that("la selección incremental respeta modified y 30 días", {
  checked_at <- as.POSIXct("2026-08-28 12:00:00", tz = "UTC")

  testthat::expect_true(metagesToolkit:::.gbif_is_due(
    as.POSIXct("2026-08-01", tz = "UTC"),
    as.POSIXct(NA, tz = "UTC"),
    NA_character_, checked_at
  ))
  testthat::expect_true(metagesToolkit:::.gbif_is_due(
    as.POSIXct("2026-08-20", tz = "UTC"),
    as.POSIXct("2026-08-10", tz = "UTC"),
    "ok", checked_at
  ))
  testthat::expect_false(metagesToolkit:::.gbif_is_due(
    as.POSIXct("2026-08-01", tz = "UTC"),
    as.POSIXct("2026-08-10", tz = "UTC"),
    "ok", checked_at
  ))
  testthat::expect_true(metagesToolkit:::.gbif_is_due(
    as.POSIXct("2026-01-01", tz = "UTC"),
    as.POSIXct("2026-08-27", tz = "UTC"),
    "ok", checked_at, force_full = TRUE
  ))
})

testthat::test_that("solo tres 404 definitivos preparan la ocultación", {
  transition <- metagesToolkit:::.gbif_availability_transition(
    probe = list(status = 404L, body = NULL, error = NA_character_),
    current_streak = 1L,
    resource_private = 0L,
    workflow_hidden = 0L,
    spanish_publisher_keys = character()
  )
  testthat::expect_equal(transition$streak, 2L)
  testthat::expect_equal(transition$action, "none")

  transition <- metagesToolkit:::.gbif_availability_transition(
    probe = list(status = 410L, body = NULL, error = NA_character_),
    current_streak = 2L,
    resource_private = 0L,
    workflow_hidden = 0L,
    spanish_publisher_keys = character()
  )
  testthat::expect_equal(transition$streak, 3L)
  testthat::expect_equal(transition$action, "review_private")
})

testthat::test_that("un error temporal no incrementa ausencias", {
  transition <- metagesToolkit:::.gbif_availability_transition(
    probe = list(status = NA_integer_, body = NULL, error = "timeout"),
    current_streak = 2L,
    resource_private = 0L,
    workflow_hidden = 0L,
    spanish_publisher_keys = character()
  )
  testthat::expect_equal(transition$status, "error")
  testthat::expect_equal(transition$streak, 2L)
  testthat::expect_equal(transition$action, "none")
})

testthat::test_that("reaparición solo revierte una ocultación del workflow", {
  uuid <- "11111111-1111-1111-1111-111111111111"
  probe <- list(
    status = 200L,
    body = list(publishingOrganizationKey = uuid),
    error = NA_character_
  )

  own <- metagesToolkit:::.gbif_availability_transition(
    probe, 0L, 1L, 1L, uuid
  )
  manual <- metagesToolkit:::.gbif_availability_transition(
    probe, 0L, 1L, 0L, uuid
  )
  testthat::expect_equal(own$action, "review_public")
  testthat::expect_equal(manual$action, "none")

  probe$body$publishingOrganizationKey <-
    "22222222-2222-2222-2222-222222222222"
  outside <- metagesToolkit:::.gbif_availability_transition(
    probe, 0L, 1L, 1L, uuid
  )
  testthat::expect_equal(outside$status, "outside_spain")
  testthat::expect_equal(outside$action, "review_public")
})

testthat::test_that("publisher y endpoints quedan relacionados al dataset", {
  publishers <- data.frame(
    publisher_key = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    publisher_name = "Publisher ES",
    publisher_country = "ES",
    publisher_modified_at = as.POSIXct("2026-08-01", tz = "UTC")
  )
  datasets <- list(list(
    key = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    title = "Dataset",
    type = "OCCURRENCE",
    modified = "2026-08-20T10:00:00Z",
    pubDate = "2026-08-19T00:00:00Z",
    version = "1.0",
    publishingOrganizationKey = publishers$publisher_key,
    publishingOrganizationTitle = "Nombre antiguo",
    endpoints = list(
      list(type = "DWC_ARCHIVE", url = "https://example.org/dwca.zip"),
      list(type = "EML", url = "https://example.org/eml.xml")
    )
  ))

  out <- metagesToolkit:::.gbif_dataset_rows(datasets, publishers)
  testthat::expect_equal(out$publisher_name, "Publisher ES")
  testthat::expect_equal(out$publisher_country, "ES")
  testthat::expect_equal(out$dwca_url, "https://example.org/dwca.zip")
  testthat::expect_equal(out$eml_url, "https://example.org/eml.xml")
})


.gbif_test_empty_resources <- function() {
  data.frame(
    recurso_fk = integer(),
    uuid = character(),
    url_gbiforg = character(),
    url_ipt = character(),
    private = integer(),
    tipo_recurso_id = integer(),
    tipo_recurso = character(),
    baseline_title = character(),
    baseline_reference_date = character(),
    baseline_occurrences = character(),
    baseline_version = character(),
    last_checked_at = as.POSIXct(character(), tz = "UTC"),
    monitor_status = character(),
    gbif_availability_status = character(),
    gbif_not_found_streak = integer(),
    visibility_action = character(),
    visibility_applied_by_workflow = integer(),
    stringsAsFactors = FALSE
  )
}


.gbif_test_resource <- function(
    recurso_fk,
    dataset_uuid,
    private = 0L,
    workflow_hidden = 0L
) {
  data.frame(
    recurso_fk = recurso_fk,
    uuid = dataset_uuid,
    url_gbiforg = paste0("https://www.gbif.org/dataset/", dataset_uuid),
    url_ipt = NA_character_,
    private = private,
    tipo_recurso_id = 223L,
    tipo_recurso = "Dataset",
    baseline_title = "Dataset ES",
    baseline_reference_date = "2026-08-20",
    baseline_occurrences = "10",
    baseline_version = "1.0",
    last_checked_at = as.POSIXct("2026-09-13", tz = "UTC"),
    monitor_status = "ok",
    gbif_availability_status = "available",
    gbif_not_found_streak = 0L,
    visibility_action = "none",
    visibility_applied_by_workflow = workflow_hidden,
    stringsAsFactors = FALSE
  )
}


.gbif_test_spanish_dataset_inventory <- function(dataset_uuid) {
  publisher_key <- "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  .gbif_test_inventory(
    datasets = list(list(
      key = dataset_uuid,
      title = "Dataset ES",
      type = "OCCURRENCE",
      modified = "2026-08-20T00:00:00Z",
      pubDate = "2026-08-20",
      version = "1.0",
      publishingOrganizationKey = publisher_key
    )),
    publishers = list(list(
      key = publisher_key,
      title = "Publisher ES",
      country = "ES",
      modified = "2026-08-20T00:00:00Z"
    ))
  )
}


.gbif_test_inventory <- function(datasets = list(), publishers = list()) {
  publisher_rows <- metagesToolkit:::.gbif_organization_rows(publishers)
  list(
    publishers = publisher_rows,
    datasets = metagesToolkit:::.gbif_dataset_rows(datasets, publisher_rows),
    raw_publishers = publishers,
    raw_datasets = datasets
  )
}


testthat::test_that("un UUID público y privado corresponde al recurso público", {
  dataset_uuid <- "11111111-1111-1111-1111-111111111111"
  resources <- dplyr::bind_rows(
    .gbif_test_resource(10L, dataset_uuid, private = 0L),
    .gbif_test_resource(11L, dataset_uuid, private = 1L)
  )

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) {
      .gbif_test_spanish_dataset_inventory(dataset_uuid)
    },
    .gbif_load_metages_resources = function(con) resources,
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE,
    checked_at = as.POSIXct("2026-09-14", tz = "UTC")
  )

  testthat::expect_equal(out$datasets$match_status, "existing")
  testthat::expect_equal(out$datasets$metages_public_matches, 1L)
  testthat::expect_equal(out$datasets$metages_private_matches, 1L)
  testthat::expect_equal(out$existing_skipped$recurso_fk, 10L)
  testthat::expect_equal(nrow(out$new_candidates), 0L)
  testthat::expect_equal(nrow(out$identity_errors), 0L)
})


testthat::test_that("un privado del workflow no reabre si el UUID ya es público", {
  dataset_uuid <- "12121212-1212-1212-1212-121212121212"
  resources <- dplyr::bind_rows(
    .gbif_test_resource(12L, dataset_uuid, private = 0L),
    .gbif_test_resource(
      13L,
      dataset_uuid,
      private = 1L,
      workflow_hidden = 1L
    )
  )

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) {
      .gbif_test_spanish_dataset_inventory(dataset_uuid)
    },
    .gbif_load_metages_resources = function(con) resources,
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE
  )

  testthat::expect_equal(out$datasets$match_status, "existing")
  testthat::expect_false(13L %in% out$availability$recurso_fk)
  testthat::expect_false(any(
    out$availability$visibility_action == "review_public"
  ))
})


testthat::test_that("dos recursos públicos generan un error de identidad", {
  dataset_uuid <- "22222222-2222-2222-2222-222222222222"
  resources <- dplyr::bind_rows(
    .gbif_test_resource(20L, dataset_uuid, private = 0L),
    .gbif_test_resource(21L, dataset_uuid, private = 0L)
  )

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) {
      .gbif_test_spanish_dataset_inventory(dataset_uuid)
    },
    .gbif_load_metages_resources = function(con) resources,
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE
  )

  testthat::expect_equal(out$datasets$match_status, "identity_error")
  testthat::expect_equal(nrow(out$new_candidates), 0L)
  testthat::expect_equal(nrow(out$identity_errors), 1L)
  testthat::expect_equal(out$identity_errors$public_recurso_fks, "20,21")
  testthat::expect_equal(nrow(out$existing_checked), 0L)
  testthat::expect_equal(nrow(out$availability), 0L)
})


testthat::test_that("las coincidencias solo privadas no son altas nuevas", {
  dataset_uuid <- "33333333-3333-3333-3333-333333333333"
  resources <- dplyr::bind_rows(
    .gbif_test_resource(30L, dataset_uuid, private = 1L),
    .gbif_test_resource(31L, dataset_uuid, private = 1L)
  )

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) {
      .gbif_test_spanish_dataset_inventory(dataset_uuid)
    },
    .gbif_load_metages_resources = function(con) resources,
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE
  )

  testthat::expect_equal(out$datasets$match_status, "existing_private")
  testthat::expect_equal(nrow(out$new_candidates), 0L)
  testthat::expect_equal(nrow(out$identity_errors), 0L)
  testthat::expect_equal(nrow(out$availability), 0L)
})


testthat::test_that("solo un UUID ausente llega a new_candidates", {
  dataset_uuid <- "55555555-5555-5555-5555-555555555555"

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) {
      .gbif_test_spanish_dataset_inventory(dataset_uuid)
    },
    .gbif_load_metages_resources = function(con) {
      .gbif_test_empty_resources()
    },
    .gbif_extract_dataset_metadata = function(
        df,
        progress = TRUE,
        request_delay = 0.2,
        dataset_details = NULL
    ) {
      dplyr::mutate(
        df,
        eml_title = "Dataset ES",
        eml_version = "1.0",
        eml_pub_date = "2026-08-20",
        eml_occurrences = 10,
        detected_dwca_url = "https://ipt.example.org/archive.do?r=dataset",
        detected_eml_url = "https://ipt.example.org/eml.do?r=dataset",
        eml_status = "ok",
        eml_error_message = NA_character_
      )
    },
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE
  )

  testthat::expect_equal(out$datasets$match_status, "missing")
  testthat::expect_equal(out$new_candidates$gbif_dataset_uuid, dataset_uuid)
  testthat::expect_equal(out$new_candidates$match_status, "missing")
  testthat::expect_equal(out$new_candidates$extraction_status, "ok")
  testthat::expect_equal(
    out$new_candidates$dwca_url,
    "https://ipt.example.org/archive.do?r=dataset"
  )
  testthat::expect_equal(
    out$new_candidates$eml_url,
    "https://ipt.example.org/eml.do?r=dataset"
  )
})


testthat::test_that("solo se monitoriza un privado ocultado por el workflow", {
  dataset_uuid <- "44444444-4444-4444-4444-444444444444"
  resources <- dplyr::bind_rows(
    .gbif_test_resource(40L, dataset_uuid, private = 1L),
    .gbif_test_resource(
      41L,
      dataset_uuid,
      private = 1L,
      workflow_hidden = 1L
    )
  )

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) {
      .gbif_test_spanish_dataset_inventory(dataset_uuid)
    },
    .gbif_load_metages_resources = function(con) resources,
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE
  )

  testthat::expect_equal(out$availability$recurso_fk, 41L)
  testthat::expect_equal(out$availability$visibility_action, "review_public")
})


testthat::test_that("un IPT sin UUID resoluble se excluye y se documenta", {
  resources <- .gbif_test_resource(
    42L,
    "66666666-6666-6666-6666-666666666666"
  )
  resources$uuid <- NA_character_
  resources$url_gbiforg <- NA_character_
  resources$url_ipt <- "https://ipt.example.org/resource?r=dataset"

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) .gbif_test_inventory(),
    .gbif_load_metages_resources = function(con) resources,
    .gbif_dataset_key_from_dwca = function(url) {
      stop("fallo temporal resolviendo IPT")
    },
    .package = "metagesToolkit"
  )

  out <- testthat::expect_no_error(
    run_gbif_spain_workflow(
      con = structure(list(), class = "fake_con"),
      progress = FALSE,
      request_delay = 0,
      write = FALSE
    )
  )
  testthat::expect_equal(out$unresolved_resources$recurso_fk, 42L)
  testthat::expect_match(
    out$unresolved_resources$workflow_exclusion_reason,
    "fallo temporal resolviendo IPT"
  )
  testthat::expect_true(is.na(
    out$unresolved_resources$gbif_dataset_uuid
  ))
  testthat::expect_equal(nrow(out$existing_checked), 0L)
  testthat::expect_equal(nrow(out$availability), 0L)
})


testthat::test_that("staging retira UUID ya presentes en MetaGES", {
  deleted_uuids <- character()
  testthat::local_mocked_bindings(
    dbExecute = function(con, statement, params, ...) {
      deleted_uuids <<- c(deleted_uuids, params[[1]])
      1L
    },
    .package = "DBI"
  )

  deleted <- metagesToolkit:::.gbif_reconcile_new_candidates(
    structure(list(), class = "fake_con"),
    c(
      "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
      NA,
      "",
      "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    )
  )

  testthat::expect_equal(deleted, 1L)
  testthat::expect_equal(
    deleted_uuids,
    "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  )
})


testthat::test_that("el inventario conserva respuestas raw y relaciones", {
  publisher_key <- "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  dataset_key <- "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  raw_publishers <- list(list(
    key = publisher_key,
    title = "Publisher ES",
    country = "ES",
    modified = "2026-08-01T00:00:00.123+00:00",
    extraField = "conservado"
  ))
  raw_datasets <- list(list(
    key = dataset_key,
    title = "Dataset ES",
    type = "OCCURRENCE",
    modified = "2026-08-20T10:00:00.456+02:00",
    publishingOrganizationKey = publisher_key,
    publishingOrganizationTitle = "Nombre API",
    hostingOrganizationKey = "cccccccc-cccc-cccc-cccc-cccccccccccc",
    installationKey = "dddddddd-dddd-dddd-dddd-dddddddddddd",
    extraField = list(value = 1L)
  ))

  testthat::local_mocked_bindings(
    .gbif_paginate = function(path, ...) {
      if (identical(path, "/organization")) raw_publishers else raw_datasets
    },
    .gbif_api_get_json = function(path, query = list()) raw_datasets[[1]],
    .gbif_sleep = function(...) invisible(NULL),
    .package = "metagesToolkit"
  )

  out <- fetch_gbif_spain_inventory(request_delay = 0)

  testthat::expect_identical(out$raw_publishers, raw_publishers)
  testthat::expect_identical(unname(out$raw_datasets), raw_datasets)
  testthat::expect_equal(out$datasets$publisher_name, "Publisher ES")
  testthat::expect_equal(
    out$publishers$publisher_modified_at,
    as.POSIXct("2026-08-01 00:00:00", tz = "UTC")
  )
  testthat::expect_equal(
    out$datasets$gbif_modified_at,
    as.POSIXct("2026-08-20 08:00:00", tz = "UTC")
  )
  testthat::expect_equal(
    out$datasets$hosting_key,
    "cccccccc-cccc-cccc-cccc-cccccccccccc"
  )
  testthat::expect_equal(
    out$datasets$installation_key,
    "dddddddd-dddd-dddd-dddd-dddddddddddd"
  )
})


testthat::test_that("el inventario obtiene endpoints desde el detalle", {
  publisher_key <- "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  dataset_key <- "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  detail_calls <- character()

  testthat::local_mocked_bindings(
    .gbif_paginate = function(path, ...) {
      if (identical(path, "/organization")) {
        list(list(
          key = publisher_key,
          title = "Publisher ES",
          country = "ES"
        ))
      } else {
        list(list(
          key = dataset_key,
          title = "Dataset ES",
          type = "OCCURRENCE",
          publishingOrganizationKey = publisher_key
        ))
      }
    },
    .gbif_api_get_json = function(path, query = list()) {
      detail_calls <<- c(detail_calls, path)
      list(
        key = dataset_key,
        title = "Dataset ES",
        type = "OCCURRENCE",
        publishingOrganizationKey = publisher_key,
        endpoints = list(
          list(
            type = "DWC_ARCHIVE",
            url = "https://ipt.example.org/archive.do?r=dataset"
          ),
          list(
            type = "EML",
            url = "https://ipt.example.org/eml.do?r=dataset"
          )
        )
      )
    },
    .gbif_sleep = function(...) invisible(NULL),
    .package = "metagesToolkit"
  )

  out <- fetch_gbif_spain_inventory(request_delay = 0)

  testthat::expect_equal(detail_calls, paste0("/dataset/", dataset_key))
  testthat::expect_equal(
    out$datasets$dwca_url,
    "https://ipt.example.org/archive.do?r=dataset"
  )
  testthat::expect_equal(
    out$datasets$eml_url,
    "https://ipt.example.org/eml.do?r=dataset"
  )
  testthat::expect_equal(
    out$raw_datasets[[1]]$endpoints[[1]]$type,
    "DWC_ARCHIVE"
  )
})


testthat::test_that("la paginación conserva todas las páginas y aplica pausa", {
  offsets <- integer()
  sleeps <- 0L

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      offsets <<- c(offsets, query$offset)
      if (query$offset == 0L) {
        list(
          results = list(list(key = "a"), list(key = "b")),
          count = 3L,
          endOfRecords = FALSE
        )
      } else {
        list(
          results = list(list(key = "c")),
          count = 3L,
          endOfRecords = TRUE
        )
      }
    },
    .gbif_sleep = function(...) {
      sleeps <<- sleeps + 1L
      invisible(NULL)
    },
    .package = "metagesToolkit"
  )

  out <- metagesToolkit:::.gbif_paginate(
    "/dataset/search",
    page_limit = 2L,
    request_delay = 0.2
  )

  testthat::expect_equal(vapply(out, `[[`, character(1), "key"), c("a", "b", "c"))
  testthat::expect_equal(offsets, c(0L, 2L))
  testthat::expect_equal(sleeps, 1L)
})


testthat::test_that("write=FALSE no abre transacción ni escribe monitores", {
  writes <- 0L
  inventory <- .gbif_test_inventory()

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) inventory,
    .gbif_load_metages_resources = function(con) {
      .gbif_test_empty_resources()
    },
    .gbif_reconcile_new_candidates = function(...) {
      writes <<- writes + 1L
    },
    .gbif_upsert_new_candidates = function(...) {
      writes <<- writes + 1L
    },
    .gbif_upsert_monitor_content = function(...) {
      writes <<- writes + 1L
    },
    .gbif_upsert_monitor_endpoints = function(...) {
      writes <<- writes + 1L
    },
    .gbif_insert_monitor_log = function(...) {
      writes <<- writes + 1L
    },
    .gbif_upsert_availability = function(...) {
      writes <<- writes + 1L
    },
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = FALSE
  )

  testthat::expect_false(out$write)
  testthat::expect_equal(writes, 0L)
  testthat::expect_equal(nrow(out$new_candidates), 0L)
  testthat::expect_equal(nrow(out$existing_checked), 0L)
})


testthat::test_that("force_full incluye un recurso disponible fuera de España", {
  dataset_key <- "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
  resources <- .gbif_test_empty_resources()
  resources[1, ] <- list(
    41L,
    dataset_key,
    paste0("https://www.gbif.org/dataset/", dataset_key),
    NA_character_,
    0L,
    223L,
    "Dataset",
    "Título anterior",
    "2026-01-01",
    "10",
    "1.0",
    as.POSIXct("2026-08-27", tz = "UTC"),
    "ok",
    "available",
    0L,
    "none",
    0L
  )
  extracted <- NULL
  compared <- NULL

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) .gbif_test_inventory(),
    .gbif_load_metages_resources = function(con) resources,
    .gbif_probe_dataset = function(dataset_uuid) list(
      status = 200L,
      body = list(
        key = dataset_uuid,
        title = "Dataset francés",
        type = "OCCURRENCE",
        modified = "2026-08-20T00:00:00Z",
        pubDate = "2026-08-19",
        version = "2.0",
        publishingCountry = "FR",
        publishingOrganizationKey =
          "ffffffff-ffff-ffff-ffff-ffffffffffff"
      ),
      error = NA_character_
    ),
    .gbif_extract_dataset_metadata = function(
        df,
        progress = TRUE,
        request_delay = 0.2,
        dataset_details = NULL
    ) {
      extracted <<- df
      dplyr::mutate(
        df,
        eml_title = "Dataset francés",
        eml_version = "2.0",
        eml_pub_date = "2026-08-19",
        eml_occurrences = 12,
        eml_status = "ok",
        eml_error_message = NA_character_
      )
    },
    .gbif_compare_resource_snapshot = function(snapshot_df, checked_at) {
      compared <<- snapshot_df
      list(
        current_upsert_df = data.frame(),
        log_insert_df = data.frame(),
        comparison_df = dplyr::mutate(
          snapshot_df,
          title_changed = TRUE,
          occurrences_changed = TRUE
        )
      )
    },
    .package = "metagesToolkit"
  )

  out <- run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    force_full = TRUE,
    write = FALSE,
    checked_at = as.POSIXct("2026-08-28", tz = "UTC")
  )

  testthat::expect_equal(extracted$recurso_fk, 41L)
  testthat::expect_equal(compared$gbif_dataset_uuid, dataset_key)
  testthat::expect_equal(out$existing_checked$inventory_scope, "outside_inventory")
  testthat::expect_equal(
    out$summary$value[out$summary$metric ==
      "existing_checked_outside_inventory"],
    1
  )
})


testthat::test_that("el modo escritura hace rollback ante cualquier fallo", {
  begin_calls <- 0L
  commit_calls <- 0L
  rollback_calls <- 0L

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) .gbif_test_inventory(),
    .gbif_load_metages_resources = function(con) {
      .gbif_test_empty_resources()
    },
    .gbif_upsert_new_candidates = function(...) stop("fallo controlado"),
    .package = "metagesToolkit"
  )
  testthat::local_mocked_bindings(
    dbBegin = function(con, ...) {
      begin_calls <<- begin_calls + 1L
      TRUE
    },
    dbCommit = function(con, ...) {
      commit_calls <<- commit_calls + 1L
      TRUE
    },
    dbRollback = function(con, ...) {
      rollback_calls <<- rollback_calls + 1L
      TRUE
    },
    .package = "DBI"
  )

  testthat::expect_error(
    run_gbif_spain_workflow(
      con = structure(list(), class = "fake_con"),
      progress = FALSE,
      request_delay = 0,
      write = TRUE
    ),
    "fallo controlado"
  )
  testthat::expect_equal(begin_calls, 1L)
  testthat::expect_equal(commit_calls, 0L)
  testthat::expect_equal(rollback_calls, 1L)
})


testthat::test_that("el modo escritura agrupa los monitores en una transacción", {
  begin_calls <- 0L
  commit_calls <- 0L
  rollback_calls <- 0L
  writes <- character()

  testthat::local_mocked_bindings(
    fetch_gbif_spain_inventory = function(...) .gbif_test_inventory(),
    .gbif_load_metages_resources = function(con) {
      .gbif_test_empty_resources()
    },
    .gbif_reconcile_new_candidates = function(...) {
      writes <<- c(writes, "reconcile")
    },
    .gbif_upsert_new_candidates = function(...) {
      writes <<- c(writes, "new")
    },
    .gbif_upsert_monitor_content = function(...) {
      writes <<- c(writes, "content")
    },
    .gbif_upsert_monitor_endpoints = function(...) {
      writes <<- c(writes, "endpoints")
    },
    .gbif_insert_monitor_log = function(...) {
      writes <<- c(writes, "log")
    },
    .gbif_upsert_availability = function(...) {
      writes <<- c(writes, "availability")
    },
    .package = "metagesToolkit"
  )
  testthat::local_mocked_bindings(
    dbBegin = function(con, ...) {
      begin_calls <<- begin_calls + 1L
      TRUE
    },
    dbCommit = function(con, ...) {
      commit_calls <<- commit_calls + 1L
      TRUE
    },
    dbRollback = function(con, ...) {
      rollback_calls <<- rollback_calls + 1L
      TRUE
    },
    .package = "DBI"
  )

  run_gbif_spain_workflow(
    con = structure(list(), class = "fake_con"),
    progress = FALSE,
    request_delay = 0,
    write = TRUE
  )

  testthat::expect_equal(begin_calls, 1L)
  testthat::expect_equal(commit_calls, 1L)
  testthat::expect_equal(rollback_calls, 0L)
  testthat::expect_equal(
    writes,
    c("reconcile", "new", "content", "endpoints", "log", "availability")
  )
})
