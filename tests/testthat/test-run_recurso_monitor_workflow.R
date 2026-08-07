testthat::test_that("run_recurso_monitor_workflow() devuelve salida vacía si no hay recursos", {
  PKG <- "metagesToolkit"
  
  fake_con_1 <- structure(list(id = "read"), class = "fake_con")
  fake_ssh_1 <- structure(list(id = "ssh_read"), class = "fake_ssh")
  
  disconnect_calls <- 0L
  ssh_disconnect_calls <- 0L
  
  testthat::local_mocked_bindings(
    conectar_metages = function() {
      list(con = fake_con_1, ssh = fake_ssh_1)
    },
    .package = PKG
  )
  
  testthat::local_mocked_bindings(
    dbGetQuery = function(con, statement, ...) {
      data.frame()
    },
    dbDisconnect = function(con, ...) {
      disconnect_calls <<- disconnect_calls + 1L
      TRUE
    },
    .package = "DBI"
  )
  
  testthat::local_mocked_bindings(
    ssh_disconnect = function(session, ...) {
      ssh_disconnect_calls <<- ssh_disconnect_calls + 1L
      invisible(TRUE)
    },
    .package = "ssh"
  )
  
  out <- run_recurso_monitor_workflow(
    progress = FALSE,
    checked_at = as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  )
  
  testthat::expect_true(is.list(out))
  testthat::expect_equal(nrow(out$input_df), 0L)
  testthat::expect_equal(nrow(out$snapshot_df), 0L)
  testthat::expect_equal(nrow(out$current_upsert_df), 0L)
  testthat::expect_equal(nrow(out$log_insert_df), 0L)
  testthat::expect_equal(nrow(out$comparison_df), 0L)
  testthat::expect_gte(disconnect_calls, 1L)
  testthat::expect_gte(ssh_disconnect_calls, 1L)
})

testthat::test_that("run_recurso_monitor_workflow() usa fuente priorizada y llama a extract y compare", {
  PKG <- "metagesToolkit"
  
  fake_con_1 <- structure(list(id = "read"), class = "fake_con")
  fake_con_2 <- structure(list(id = "write"), class = "fake_con")
  fake_ssh_1 <- structure(list(id = "ssh_read"), class = "fake_ssh")
  fake_ssh_2 <- structure(list(id = "ssh_write"), class = "fake_ssh")
  
  connect_calls <- 0L
  disconnect_calls <- 0L
  ssh_disconnect_calls <- 0L
  extract_input <- NULL
  compare_input <- NULL
  executed_sql <- character(0)
  read_sql <- NULL
  executed_params <- list()
  begin_calls <- 0L
  commit_calls <- 0L
  rollback_calls <- 0L
  
  input_df_db <- data.frame(
    recurso_fk = c(1L, 2L),
    tipo_recurso_id = c(223L, 225L),
    tipo_recurso = c("Dataset", "Checklist"),
    url_ipt = c(
      "https://ipt.org/manage/resource?r=a",
      "https://ipt.org/archive.do?r=b"
    ),
    dwca_url = c(
      "11111111-1111-1111-1111-111111111111",
      "https://www.gbif.org/dataset/22222222-2222-2222-2222-222222222222"
    ),
    baseline_title = c(" Título A ", ""),
    baseline_reference_date = c(" 2024-01-01 ", ""),
    baseline_occurrences = c("10", ""),
    baseline_version = c(" v=1.0 ", ""),
    stringsAsFactors = FALSE
  )
  
  snapshot_fake <- data.frame(
    recurso_fk = c(1L, 2L),
    tipo_recurso_id = c(223L, 225L),
    tipo_recurso = c("Dataset", "Checklist"),
    url_ipt = c(
      "https://ipt.org/manage/resource?r=a",
      "https://ipt.org/archive.do?r=b"
    ),
    baseline_title = c("Título A", NA),
    baseline_reference_date = c("2024-01-01", NA),
    baseline_occurrences = c(10, NA),
    baseline_version = c("v=1.0", NA),
    dwca_url = c(
      "11111111-1111-1111-1111-111111111111",
      "https://www.gbif.org/dataset/22222222-2222-2222-2222-222222222222"
    ),
    eml_title = c("Título A", "B"),
    eml_version = c("1.0", "1.0"),
    eml_pub_date = c("2024-01-01", "2024-01-01"),
    eml_occurrences = c(10, 20),
    eml_status = c("ok", "ok"),
    eml_error_message = c(NA, NA),
    stringsAsFactors = FALSE
  )
  
  cmp_fake <- list(
    current_upsert_df = data.frame(
      recurso_fk = c(1L, 2L),
      tipo_recurso = c("Dataset", "Checklist"),
      last_checked_at = as.POSIXct(c("2026-04-15 10:00:00", "2026-04-15 10:00:00"), tz = "UTC"),
      last_change_at = as.POSIXct(c(NA, "2026-04-15 10:00:00"), tz = "UTC"),
      eml_title_detected = c("Título A", "B"),
      previous_eml_title_detected = c("Título A", NA),
      eml_version_detected = c("1.0", "1.0"),
      previous_eml_version_detected = c("1.0", NA),
      eml_pub_date_detected = c("2024-01-01", "2024-01-01"),
      previous_eml_pub_date_detected = c("2024-01-01", NA),
      occurrences_detected = c(10, 20),
      previous_occurrences_detected = c(10, NA),
      occurrences_diff_last_check = c(0, NA),
      monitor_status = c("ok", "ok"),
      monitor_error_message = c(NA, NA),
      change_flag = c(0L, 1L),
      change_type = c("unchanged", "title"),
      stringsAsFactors = FALSE
    ),
    log_insert_df = data.frame(
      recurso_fk = 2L,
      tipo_recurso = "Checklist",
      event_at = as.POSIXct("2026-04-15 10:00:00", tz = "UTC"),
      event_type = "title",
      previous_eml_title_detected = NA_character_,
      new_eml_title_detected = "B",
      previous_eml_version_detected = NA_character_,
      new_eml_version_detected = "1.0",
      previous_eml_pub_date_detected = NA_character_,
      new_eml_pub_date_detected = "2024-01-01",
      previous_occurrences_detected = NA_real_,
      new_occurrences_detected = 20,
      occurrences_diff = NA_real_,
      previous_monitor_status = NA_character_,
      new_monitor_status = "ok",
      monitor_error_message = NA_character_,
      stringsAsFactors = FALSE
    ),
    comparison_df = data.frame(dummy = 1)
  )
  
  testthat::local_mocked_bindings(
    conectar_metages = function() {
      connect_calls <<- connect_calls + 1L
      if (connect_calls == 1L) {
        list(con = fake_con_1, ssh = fake_ssh_1)
      } else {
        list(con = fake_con_2, ssh = fake_ssh_2)
      }
    },
    extract_gbif_metadata = function(df, progress = TRUE) {
      extract_input <<- df
      snapshot_fake
    },
    compare_recurso_monitor_snapshot = function(snapshot_df, checked_at = Sys.time()) {
      compare_input <<- list(snapshot_df = snapshot_df, checked_at = checked_at)
      cmp_fake
    },
    .package = PKG
  )
  
  testthat::local_mocked_bindings(
    dbGetQuery = function(con, statement, ...) {
      read_sql <<- statement
      input_df_db
    },
    dbDisconnect = function(con, ...) {
      disconnect_calls <<- disconnect_calls + 1L
      TRUE
    },
    dbBegin = function(con, ...) {
      begin_calls <<- begin_calls + 1L
      TRUE
    },
    dbExecute = function(con, statement, params = NULL, ...) {
      executed_sql <<- c(executed_sql, statement)
      executed_params[[length(executed_params) + 1L]] <<- params
      1L
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
  
  testthat::local_mocked_bindings(
    ssh_disconnect = function(session, ...) {
      ssh_disconnect_calls <<- ssh_disconnect_calls + 1L
      invisible(TRUE)
    },
    .package = "ssh"
  )
  
  checked_at <- as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
  
  out <- run_recurso_monitor_workflow(
    progress = FALSE,
    checked_at = checked_at
  )
  
  testthat::expect_equal(connect_calls, 2L)
  testthat::expect_gte(disconnect_calls, 2L)
  testthat::expect_gte(ssh_disconnect_calls, 2L)
  
  testthat::expect_equal(extract_input$baseline_title[1], "Título A")
  testthat::expect_true(is.na(extract_input$baseline_title[2]))
  testthat::expect_equal(extract_input$baseline_reference_date[1], "2024-01-01")
  testthat::expect_true(is.na(extract_input$baseline_reference_date[2]))
  testthat::expect_equal(extract_input$baseline_version[1], "v=1.0")
  testthat::expect_true(is.na(extract_input$baseline_version[2]))
  testthat::expect_equal(extract_input$baseline_occurrences[1], 10)
  testthat::expect_true(is.na(extract_input$baseline_occurrences[2]))
  
  testthat::expect_equal(
    extract_input$dwca_url[1],
    "11111111-1111-1111-1111-111111111111"
  )
  testthat::expect_equal(
    extract_input$dwca_url[2],
    "https://www.gbif.org/dataset/22222222-2222-2222-2222-222222222222"
  )
  testthat::expect_equal(extract_input$tipo_recurso_id, c(223L, 225L))
  testthat::expect_match(read_sql, "r.Tipo_recurso AS tipo_recurso_id", fixed = TRUE)
  testthat::expect_match(read_sql, "NULLIF(TRIM(r.url_gbiforg), '')", fixed = TRUE)
  
  testthat::expect_identical(compare_input$snapshot_df, snapshot_fake)
  testthat::expect_equal(compare_input$checked_at, checked_at)
  
  testthat::expect_equal(begin_calls, 1L)
  testthat::expect_equal(commit_calls, 1L)
  testthat::expect_equal(rollback_calls, 0L)
  
  testthat::expect_equal(nrow(out$input_df), 2L)
  testthat::expect_identical(out$snapshot_df, snapshot_fake)
  testthat::expect_identical(out$current_upsert_df, cmp_fake$current_upsert_df)
  testthat::expect_identical(out$log_insert_df, cmp_fake$log_insert_df)
  testthat::expect_identical(out$comparison_df, cmp_fake$comparison_df)
  
  testthat::expect_length(executed_sql, 3L)
  testthat::expect_true(grepl("INSERT INTO metages_recurso_monitor", executed_sql[1], fixed = TRUE))
  testthat::expect_true(grepl("INSERT INTO metages_recurso_monitor", executed_sql[2], fixed = TRUE))
  testthat::expect_true(grepl("INSERT INTO metages_recurso_monitor_log", executed_sql[3], fixed = TRUE))
})

testthat::test_that("run_recurso_monitor_workflow() hace rollback si falla una escritura", {
  PKG <- "metagesToolkit"
  
  fake_con_1 <- structure(list(id = "read"), class = "fake_con")
  fake_con_2 <- structure(list(id = "write"), class = "fake_con")
  fake_ssh_1 <- structure(list(id = "ssh_read"), class = "fake_ssh")
  fake_ssh_2 <- structure(list(id = "ssh_write"), class = "fake_ssh")
  
  connect_calls <- 0L
  begin_calls <- 0L
  commit_calls <- 0L
  rollback_calls <- 0L
  execute_calls <- 0L
  
  input_df_db <- data.frame(
    recurso_fk = 1L,
    tipo_recurso_id = 223L,
    tipo_recurso = "Dataset",
    url_ipt = "https://ipt.org/resource?r=x",
    dwca_url = "33333333-3333-3333-3333-333333333333",
    baseline_title = "A",
    baseline_reference_date = "2024-01-01",
    baseline_occurrences = "10",
    baseline_version = "1.0",
    stringsAsFactors = FALSE
  )
  
  snapshot_fake <- data.frame(
    recurso_fk = 1L,
    tipo_recurso_id = 223L,
    tipo_recurso = "Dataset",
    url_ipt = "https://ipt.org/resource?r=x",
    baseline_title = "A",
    baseline_reference_date = "2024-01-01",
    baseline_occurrences = 10,
    baseline_version = "1.0",
    dwca_url = "33333333-3333-3333-3333-333333333333",
    eml_title = "B",
    eml_version = "1.0",
    eml_pub_date = "2024-01-01",
    eml_occurrences = 10,
    eml_status = "ok",
    eml_error_message = NA_character_,
    stringsAsFactors = FALSE
  )
  
  cmp_fake <- list(
    current_upsert_df = data.frame(
      recurso_fk = 1L,
      tipo_recurso = "Dataset",
      last_checked_at = as.POSIXct("2026-04-15 10:00:00", tz = "UTC"),
      last_change_at = as.POSIXct("2026-04-15 10:00:00", tz = "UTC"),
      eml_title_detected = "B",
      previous_eml_title_detected = "A",
      eml_version_detected = "1.0",
      previous_eml_version_detected = "1.0",
      eml_pub_date_detected = "2024-01-01",
      previous_eml_pub_date_detected = "2024-01-01",
      occurrences_detected = 10,
      previous_occurrences_detected = 10,
      occurrences_diff_last_check = 0,
      monitor_status = "ok",
      monitor_error_message = NA_character_,
      change_flag = 1L,
      change_type = "title",
      stringsAsFactors = FALSE
    ),
    log_insert_df = data.frame(
      recurso_fk = 1L,
      tipo_recurso = "Dataset",
      event_at = as.POSIXct("2026-04-15 10:00:00", tz = "UTC"),
      event_type = "title",
      previous_eml_title_detected = "A",
      new_eml_title_detected = "B",
      previous_eml_version_detected = "1.0",
      new_eml_version_detected = "1.0",
      previous_eml_pub_date_detected = "2024-01-01",
      new_eml_pub_date_detected = "2024-01-01",
      previous_occurrences_detected = 10,
      new_occurrences_detected = 10,
      occurrences_diff = 0,
      previous_monitor_status = NA_character_,
      new_monitor_status = "ok",
      monitor_error_message = NA_character_,
      stringsAsFactors = FALSE
    ),
    comparison_df = data.frame(dummy = 1)
  )
  
  testthat::local_mocked_bindings(
    conectar_metages = function() {
      connect_calls <<- connect_calls + 1L
      if (connect_calls == 1L) {
        list(con = fake_con_1, ssh = fake_ssh_1)
      } else {
        list(con = fake_con_2, ssh = fake_ssh_2)
      }
    },
    extract_gbif_metadata = function(df, progress = TRUE) snapshot_fake,
    compare_recurso_monitor_snapshot = function(snapshot_df, checked_at = Sys.time()) cmp_fake,
    .package = PKG
  )
  
  testthat::local_mocked_bindings(
    dbGetQuery = function(con, statement, ...) input_df_db,
    dbDisconnect = function(con, ...) TRUE,
    dbBegin = function(con, ...) {
      begin_calls <<- begin_calls + 1L
      TRUE
    },
    dbExecute = function(con, statement, params = NULL, ...) {
      execute_calls <<- execute_calls + 1L
      if (execute_calls == 2L) {
        stop("Fallo de escritura en DB")
      }
      1L
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
  
  testthat::local_mocked_bindings(
    ssh_disconnect = function(session, ...) invisible(TRUE),
    .package = "ssh"
  )
  
  testthat::expect_error(
    run_recurso_monitor_workflow(
      progress = FALSE,
      checked_at = as.POSIXct("2026-04-15 10:00:00", tz = "UTC")
    ),
    "Fallo de escritura en DB"
  )
  
  testthat::expect_equal(begin_calls, 1L)
  testthat::expect_equal(commit_calls, 0L)
  testthat::expect_equal(rollback_calls, 1L)
})
