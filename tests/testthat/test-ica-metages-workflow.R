test_that("manual selection reports missing IDs and uses dates and privacy", {
  captured <- NULL
  local_mocked_bindings(dbGetQuery = function(conn, statement, ...) {
    captured <<- statement
    data.frame(provision_id = 2L, url_ipt = "https://ipt/resource?r=x", eligible = TRUE, ica_fields_empty = FALSE)
  }, .package = "DBI")
  result <- .ica_candidates(NULL, c(2L, 3L))
  expect_equal(result$provision_id, c(2L, 3L))
  expect_false(as.logical(result$eligible[2]))
  expect_match(captured, "r.private = 0", fixed = TRUE)
  expect_match(captured, "newer.provision_fecha > p.provision_fecha", fixed = TRUE)
  expect_match(captured, "p.fecha_validacion IS NULL", fixed = TRUE)
  expect_match(captured, "AS ica_fields_empty", fixed = TRUE)
  expect_false(grepl("AS empty\\b", captured))
  expect_equal(as.logical(result$ica_fields_empty), c(FALSE, FALSE))
  .ica_candidates(NULL)
  expect_match(captured, "AS ica_fields_empty", fixed = TRUE)
  expect_false(grepl("AS empty\\b", captured))
})

test_that("dry runs and manual inspection never write", {
  writes <- 0L
  local_mocked_bindings(
    .ica_runner_path = function() "runner.py",
    .ica_python = function(...) list(ICA = 70, Icat = 35, Icag = 25, Icad = 10,
                                    fecha_validacion = "2026-10-01"),
    conectar_metages = function(...) list(con = NULL, tunnel = list(kill = function() NULL)),
    .ica_candidates = function(...) data.frame(provision_id = c(1L, 2L, 3L),
      url_ipt = "https://ipt/resource?r=x", eligible = c(TRUE, TRUE, FALSE), ica_fields_empty = c(TRUE, FALSE, TRUE)),
    .ica_write = function(...) { writes <<- writes + 1L; TRUE })
  result <- ica_metages_workflow(provision_ids = 1:3)
  expect_equal(result$status, c("preview", "inspection", "omitted"))
  expect_equal(writes, 0L)
  result <- ica_metages_workflow(provision_ids = 1:3, write = TRUE)
  expect_equal(result$status, c("updated", "inspection", "omitted"))
  expect_equal(writes, 1L)
})

test_that("individual errors continue and only eligible empty rows get notes", {
  notes <- 0L
  local_mocked_bindings(
    .ica_runner_path = function() "runner.py",
    .ica_python = function(..., check = FALSE) { if (!check) stop("download failed"); list(ready = TRUE) },
    conectar_metages = function(...) list(con = NULL, tunnel = list(kill = function() NULL)),
    .ica_candidates = function(...) data.frame(provision_id = 1:2, url_ipt = "https://ipt/resource?r=x",
                                               eligible = TRUE, ica_fields_empty = c(TRUE, FALSE)),
    .ica_write = function(...) { notes <<- notes + 1L; TRUE })
  result <- ica_metages_workflow(provision_ids = 1:2, write = TRUE)
  expect_equal(result$status, c("error", "error"))
  expect_equal(notes, 1L)
})

test_that("query errors release the database connection and tunnel", {
  closed <- FALSE
  killed <- FALSE
  local_mocked_bindings(
    .ica_runner_path = function() "runner.py",
    .ica_python = function(...) list(ready = TRUE),
    conectar_metages = function(...) list(con = "mock", tunnel = list(kill = function() { killed <<- TRUE })),
    .ica_candidates = function(...) stop("query failed"))
  local_mocked_bindings(dbDisconnect = function(...) { closed <<- TRUE; TRUE }, .package = "DBI")
  expect_error(ica_metages_workflow(write = FALSE), "query failed")
  expect_true(closed)
  expect_true(killed)
})

test_that("invalid IDs fail before opening connections", {
  expect_error(ica_metages_workflow(provision_ids = c(1, NA)), "enteros")
  expect_error(ica_metages_workflow(provision_ids = 1.5), "enteros")
  expect_equal(nrow(ica_metages_workflow(provision_ids = integer())), 0L)
})

test_that("writes preserve observations and avoid duplicate errors", {
  observed <- NULL
  obs <- "Existing observation"
  local_mocked_bindings(
    dbWithTransaction = function(conn, code, ...) force(code),
    dbGetQuery = function(conn, statement, ...) {
      if (grepl("SELECT r.recurso_id", statement, fixed = TRUE)) data.frame(recurso_id = 1L)
      else data.frame(provision_obs = obs)
    },
    dbExecute = function(conn, statement, params, ...) {
      expect_match(statement, "updated_when = CURRENT_TIMESTAMP", fixed = TRUE)
      expect_match(statement, "updated_who = 'ica_metages_workflow'", fixed = TRUE)
      observed <<- params
      1L
    },
    .package = "DBI")
  row <- data.frame(provision_id = 1L, url_ipt = "https://ipt/resource?r=x")
  expect_true(.ica_write(NULL, row, error = "Download failed"))
  expect_match(observed[[1]], "Existing observation", fixed = TRUE)
  expect_match(observed[[1]], "[ICA] Download failed", fixed = TRUE)
  obs <- observed[[1]]
  observed <- NULL
  expect_true(.ica_write(NULL, row, error = "Download failed"))
  expect_null(observed)
})

test_that("a changed provision is not written after calculation", {
  local_mocked_bindings(
    dbWithTransaction = function(conn, code, ...) force(code),
    dbGetQuery = function(conn, statement, ...) {
      if (grepl("SELECT r.recurso_id", statement, fixed = TRUE)) data.frame(recurso_id = 1L)
      else data.frame(provision_obs = character())
    },
    dbExecute = function(...) stop("Must not write"), .package = "DBI")
  row <- data.frame(provision_id = 1L, url_ipt = "https://ipt/resource?r=x")
  expect_false(.ica_write(NULL, row, scores = list(ICA = 50)))
})

test_that("successful ICA writes include audit fields", {
  observed <- NULL
  local_mocked_bindings(
    dbWithTransaction = function(conn, code, ...) force(code),
    dbGetQuery = function(conn, statement, ...) {
      if (grepl("SELECT r.recurso_id", statement, fixed = TRUE)) data.frame(recurso_id = 1L)
      else data.frame(provision_obs = NA_character_)
    },
    dbExecute = function(conn, statement, params, ...) {
      expect_match(statement, "updated_when = CURRENT_TIMESTAMP", fixed = TRUE)
      expect_match(statement, "updated_who = 'ica_metages_workflow'", fixed = TRUE)
      observed <<- params
      1L
    }, .package = "DBI")
  scores <- list(ICA = 70, Icat = 35, Icag = 25, Icad = 10, fecha_validacion = "2026-10-04")
  row <- data.frame(provision_id = 1L, url_ipt = "https://ipt/resource?r=x")
  expect_true(.ica_write(NULL, row, scores = scores))
  expect_equal(observed, c(unname(scores), list(1L)))
})

test_that("Python receives JSON through stdin and timeout is in seconds", {
  local_mocked_bindings(run = function(command, args, stdin, timeout, ...) {
    expect_equal(timeout, 3600)
    input <- jsonlite::fromJSON(paste(readLines(stdin), collapse = "\n"))
    expect_equal(input$url_ipt, "https://ipt/resource.do?r=x")
    list(status = 0L, stderr = "", stdout =
      '{"ICA":70,"Icat":35,"Icag":25,"Icad":10,"fecha_validacion":"2026-10-01"}')
  }, .package = "processx")
  expect_equal(.ica_python("python", "runner.py", "https://ipt/resource.do?r=x")$ICA, 70)
})
