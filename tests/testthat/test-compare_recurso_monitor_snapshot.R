testthat::test_that("compare_recurso_monitor_snapshot() falla si faltan columnas obligatorias", {
  df <- data.frame(recurso_fk = 1L)
  
  testthat::expect_error(
    compare_recurso_monitor_snapshot(df),
    "A `snapshot_df` le faltan estas columnas:"
  )
})

testthat::test_that("compare_recurso_monitor_snapshot() detecta unchanged cuando no hay cambios reales", {
  checked_at <- as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  
  snapshot_df <- data.frame(
    recurso_fk = 1L,
    tipo_recurso = "Dataset",
    eml_title = " Mi recurso ",
    eml_version = "V2.0",
    eml_pub_date = "2024-01-31",
    eml_occurrences = 100L,
    eml_status = "ok",
    eml_error_message = NA_character_,
    baseline_title = "Mi recurso",
    baseline_reference_date = "2024-01-31",
    baseline_version = "2.0",
    baseline_occurrences = 100,
    stringsAsFactors = FALSE
  )
  
  out <- compare_recurso_monitor_snapshot(snapshot_df, checked_at = checked_at)
  
  testthat::expect_true(is.list(out))
  testthat::expect_true(all(c("current_upsert_df", "log_insert_df", "comparison_df") %in% names(out)))
  
  cmp <- out$comparison_df
  cur <- out$current_upsert_df
  log <- out$log_insert_df
  
  testthat::expect_equal(cmp$change_type, "unchanged")
  testthat::expect_equal(cmp$change_flag, 0L)
  testthat::expect_true(is.na(cmp$last_change_at))
  testthat::expect_equal(cur$change_type, "unchanged")
  testthat::expect_equal(cur$change_flag, 0L)
  testthat::expect_equal(nrow(log), 0L)
})

testthat::test_that("compare_recurso_monitor_snapshot() detecta cambios múltiples y calcula diff de occurrences", {
  checked_at <- as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  
  snapshot_df <- data.frame(
    recurso_fk = 2L,
    tipo_recurso = "Checklist",
    eml_title = "Nuevo título",
    eml_version = "V3.1",
    eml_pub_date = "2025-02-01",
    eml_occurrences = 125,
    eml_status = "ok",
    eml_error_message = NA_character_,
    baseline_title = "Título viejo",
    baseline_reference_date = "2025-01-01",
    baseline_version = "2.9",
    baseline_occurrences = 100,
    stringsAsFactors = FALSE
  )
  
  out <- compare_recurso_monitor_snapshot(snapshot_df, checked_at = checked_at)
  
  cmp <- out$comparison_df
  cur <- out$current_upsert_df
  log <- out$log_insert_df
  
  testthat::expect_true(cmp$title_changed)
  testthat::expect_true(cmp$version_changed)
  testthat::expect_true(cmp$pubdate_changed)
  testthat::expect_true(cmp$occurrences_changed)
  testthat::expect_equal(cmp$occurrences_diff_last_check, 25)
  testthat::expect_equal(cmp$change_type, "title, version, pubdate, occurrences")
  testthat::expect_equal(cmp$change_flag, 1L)
  testthat::expect_equal(cur$occurrences_diff_last_check, 25)
  testthat::expect_equal(cur$last_checked_at, checked_at)
  testthat::expect_equal(cur$last_change_at, checked_at)
  
  testthat::expect_equal(nrow(log), 1L)
  testthat::expect_equal(log$event_type, "title, version, pubdate, occurrences")
  testthat::expect_equal(log$previous_occurrences_detected, 100)
  testthat::expect_equal(log$new_occurrences_detected, 125)
  testthat::expect_equal(log$occurrences_diff, 25)
})

testthat::test_that("compare_recurso_monitor_snapshot() da prioridad a eml_status='error'", {
  checked_at <- as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  
  snapshot_df <- data.frame(
    recurso_fk = 3L,
    tipo_recurso = "Dataset",
    eml_title = NA_character_,
    eml_version = NA_character_,
    eml_pub_date = NA_character_,
    eml_occurrences = NA_real_,
    eml_status = "error",
    eml_error_message = "Fallo al descargar",
    baseline_title = "Título",
    baseline_reference_date = "2024-01-01",
    baseline_version = "1.0",
    baseline_occurrences = 50,
    stringsAsFactors = FALSE
  )
  
  out <- compare_recurso_monitor_snapshot(snapshot_df, checked_at = checked_at)
  
  cmp <- out$comparison_df
  cur <- out$current_upsert_df
  log <- out$log_insert_df
  
  testthat::expect_equal(cmp$change_type, "error")
  testthat::expect_equal(cmp$change_flag, 1L)
  testthat::expect_equal(cur$monitor_status, "error")
  testthat::expect_equal(cur$monitor_error_message, "Fallo al descargar")
  testthat::expect_equal(nrow(log), 1L)
  testthat::expect_equal(log$event_type, "error")
  testthat::expect_equal(log$new_monitor_status, "error")
})

testthat::test_that("compare_recurso_monitor_snapshot() normaliza blancos, NA y versiones con prefijo v=", {
  checked_at <- as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  
  snapshot_df <- data.frame(
    recurso_fk = 4L,
    tipo_recurso = "Dataset",
    eml_title = "  ",
    eml_version = "v= 2.4",
    eml_pub_date = "",
    eml_occurrences = "20",
    eml_status = "ok",
    eml_error_message = NA_character_,
    baseline_title = NA_character_,
    baseline_reference_date = NA_character_,
    baseline_version = "2.4",
    baseline_occurrences = 20,
    stringsAsFactors = FALSE
  )
  
  out <- compare_recurso_monitor_snapshot(snapshot_df, checked_at = checked_at)
  cmp <- out$comparison_df
  
  testthat::expect_equal(cmp$change_type, "unchanged")
  testthat::expect_equal(cmp$change_flag, 0L)
  testthat::expect_false(cmp$title_changed)
  testthat::expect_false(cmp$version_changed)
  testthat::expect_false(cmp$pubdate_changed)
  testthat::expect_false(cmp$occurrences_changed)
})

testthat::test_that("compare_recurso_monitor_snapshot() genera log solo para filas con cambio", {
  checked_at <- as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  
  snapshot_df <- data.frame(
    recurso_fk = c(10L, 11L),
    tipo_recurso = c("Dataset", "Dataset"),
    eml_title = c("A", "B nuevo"),
    eml_version = c("1.0", "1.0"),
    eml_pub_date = c("2024-01-01", "2024-01-01"),
    eml_occurrences = c(10, 20),
    eml_status = c("ok", "ok"),
    eml_error_message = c(NA, NA),
    baseline_title = c("A", "B viejo"),
    baseline_reference_date = c("2024-01-01", "2024-01-01"),
    baseline_version = c("1.0", "1.0"),
    baseline_occurrences = c(10, 20),
    stringsAsFactors = FALSE
  )
  
  out <- compare_recurso_monitor_snapshot(snapshot_df, checked_at = checked_at)
  
  testthat::expect_equal(nrow(out$current_upsert_df), 2L)
  testthat::expect_equal(nrow(out$log_insert_df), 1L)
  testthat::expect_equal(out$log_insert_df$recurso_fk, 11L)
  testthat::expect_equal(out$log_insert_df$event_type, "title")
})