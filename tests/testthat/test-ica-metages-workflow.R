test_that("manual selection reports missing IDs and uses dates and privacy", {
  captured <- NULL
  local_mocked_bindings(dbGetQuery = function(conn, statement, ...) {
    captured <<- statement
    data.frame(provision_id = 2L, url_ipt = "https://ipt/resource?r=x", eligible = TRUE, ica_fields_empty = FALSE)
  }, .package = "DBI")
  result <- .ica_candidates(NULL, c(2L, 3L))
  expect_equal(result$provision_id, c(2L, 3L))
  expect_false(as.logical(result$eligible[2]))
  expect_match(result$omission_reason[2], "Provision inexistente", fixed = TRUE)
  expect_match(captured, "AS omission_reason", fixed = TRUE)
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

test_that("las provisiones omitidas explican el motivo sin llamar al calculador", {
  reasons <- c("Provision historica: existe otra mas reciente para este recurso",
               "Recurso marcado como privado en MetaGES",
               "Privacidad del recurso no definida en MetaGES")
  local_mocked_bindings(
    .ica_runner_path = function() "runner.py",
    .ica_python = function(..., check = FALSE, update = FALSE) {
      if (!check) stop("No debe calcular provisiones omitidas")
      list(ready = TRUE)
    },
    conectar_metages = function(...) list(con = NULL, tunnel = list(kill = function() NULL)),
    .ica_candidates = function(...) data.frame(provision_id = 1:3,
      url_ipt = "https://ipt/resource?r=x", eligible = FALSE,
      ica_fields_empty = FALSE, omission_reason = reasons),
    .ica_write = function(...) stop("No debe escribir"))
  result <- ica_metages_workflow(provision_ids = 1:3, write = TRUE)
  expect_equal(result$status, rep("omitted", 3))
  expect_equal(result$detail, reasons)
})

test_that("dry runs and manual inspection never write", {
  writes <- 0L
  local_mocked_bindings(
    .ica_runner_path = function() "runner.py",
    .ica_python = function(...) list(ICA = 70, Icat = 35.1234, Icag = 0.00001, Icad = -0.00005,
                                    fecha_validacion = "2026-10-01"),
    conectar_metages = function(...) list(con = NULL, tunnel = list(kill = function() NULL)),
    .ica_candidates = function(...) data.frame(provision_id = c(1L, 2L, 3L),
      url_ipt = "https://ipt/resource?r=x", eligible = c(TRUE, TRUE, FALSE), ica_fields_empty = c(TRUE, FALSE, TRUE)),
    .ica_write = function(con, row, scores) {
      expect_equal(scores$Icag, 0.00001)
      expect_equal(scores$Icad, -0.00005)
      writes <<- writes + 1L
      TRUE
    })
  result <- ica_metages_workflow(provision_ids = 1:3)
  expect_equal(result$status, c("preview", "inspection", "omitted"))
  expect_equal(writes, 0L)
  expect_equal(result$Icag[1], 0.00001)
  expect_equal(names(result), c("provision_id", "url_ipt", "ICA", "Icat", "Icag", "Icad",
                                "fecha_validacion", "status", "detail"))
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
  local_mocked_bindings(.ica_use_wsl = function() FALSE)
  local_mocked_bindings(run = function(command, args, stdin, timeout, ...) {
    expect_equal(timeout, 3600)
    input <- jsonlite::fromJSON(paste(readLines(stdin), collapse = "\n"))
    expect_equal(input$url_ipt, "https://ipt/resource.do?r=x")
    list(status = 0L, stderr = "", stdout =
      '{"ICA":70,"Icat":35,"Icag":25,"Icad":10,"fecha_validacion":"2026-10-01"}')
  }, .package = "processx")
  expect_equal(.ica_python("python", "runner.py", "https://ipt/resource.do?r=x")$ICA, 70)
})

test_that("la actualizacion se solicita antes de conectar a MetaGES", {
  local_mocked_bindings(
    .ica_runner_path = function() "runner.py",
    .ica_python = function(..., check = FALSE, update = FALSE) {
      expect_true(check)
      expect_true(update)
      stop("Actualizacion fallida")
    },
    conectar_metages = function(...) stop("No debe conectar"))
  expect_error(ica_metages_workflow(), "Actualizacion fallida")
})

test_that("la preparacion permite actualizar una vez con limite de una hora", {
  local_mocked_bindings(.ica_use_wsl = function() FALSE)
  local_mocked_bindings(run = function(command, args, timeout, ...) {
    expect_equal(args, c("runner.py", "--check", "--prepare"))
    expect_equal(timeout, 3600)
    list(status = 0L, stderr = "", stdout = '{"ready":true}')
  }, .package = "processx")
  expect_true(.ica_python("python", "runner.py", check = TRUE, update = TRUE)$ready)
})

test_that("los fallos de Python muestran el diagnostico aunque no haya JSON", {
  local_mocked_bindings(.ica_use_wsl = function() FALSE)
  response <- list(status = 9009L, stderr = "Python no encontrado", stdout = "")
  local_mocked_bindings(run = function(...) response, .package = "processx")
  expect_error(.ica_python("python3", "runner.py", check = TRUE),
               "Python \\(python3\\), codigo de salida 9009:.*JSON\\nstderr: Python no encontrado")
  response <- list(status = 1L, stderr = "Error de arranque", stdout = "salida ajena al runner")
  expect_error(.ica_python("python3", "runner.py", check = TRUE),
               "no es JSON valido\\nstderr: Error de arranque")
  response <- list(status = 1L, stderr = "", stdout = '{"error":"Falta fcntl"}')
  expect_error(.ica_python("python3", "runner.py", check = TRUE), "Falta fcntl")
  response <- list(status = 0L, stderr = "", stdout = "null")
  expect_error(.ica_python("python3", "runner.py", check = TRUE), "no es un objeto")
  response <- list(status = 0L, stderr = "", stdout = "")
  expect_error(.ica_python("python3", "runner.py", check = TRUE), "no devolvio resultados JSON")
})

test_that("Windows delega Python a WSL y conserva stdin y argumentos con espacios", {
  local_mocked_bindings(.ica_use_wsl = function() TRUE,
                       .ica_wsl_executable = function() "wsl.exe")
  withr::local_envvar(c(METAGES_ICA_WSL_DISTRO = "Ubuntu-22.04",
                       METAGES_ICA_VENV = "/home/usuario/venv ICA",
                       METAGES_ICA_CATALOGUE_DIR = "/home/usuario/catalogo ICA"))
  runner <- tempfile("runner con espacios-", fileext = ".py")
  input <- tempfile("entrada-")
  file.create(runner, input)
  on.exit(unlink(c(runner, input)), add = TRUE)
  calls <- 0L
  local_mocked_bindings(run = function(command, args, timeout, stdin = NULL, ...) {
    calls <<- calls + 1L
    expect_equal(command, "wsl.exe")
    expect_equal(args[1:2], c("--distribution", "Ubuntu-22.04"))
    if ("wslpath" %in% args) {
      expect_equal(args[3:6], c("--exec", "wslpath", "-a", "-u"))
      return(list(status = 0L, stdout = "/mnt/c/runner con espacios.py\n", stderr = ""))
    }
    expect_equal(args[3:4], c("--exec", "env"))
    expect_true("METAGES_ICA_VENV=/home/usuario/venv ICA" %in% args)
    expect_true("METAGES_ICA_CATALOGUE_DIR=/home/usuario/catalogo ICA" %in% args)
    expect_equal(tail(args, 4), c("python3", "/mnt/c/runner con espacios.py", "--check", "--prepare"))
    expect_equal(stdin, input)
    expect_equal(timeout, 3600)
    list(status = 0L, stdout = '{"ready":true}', stderr = "")
  }, .package = "processx")
  result <- .ica_run_python("python", runner, c("--check", "--prepare"), input, 3600)
  expect_equal(result$status, 0L)
  expect_equal(calls, 2L)
})

test_that("WSL informa de su ausencia y rechaza Python nativo de Windows", {
  local_mocked_bindings(.ica_use_wsl = function() TRUE,
                       .ica_wsl_executable = function() "")
  expect_error(.ica_run_python("python3", "runner.py", character(), "input", 120), "no se encuentra wsl.exe")
  local_mocked_bindings(.ica_wsl_executable = function() "wsl.exe")
  expect_error(.ica_run_python("C:/Python/python.exe", "runner.py", character(), "input", 120),
               "Python dentro de WSL")
  local_mocked_bindings(run = function(...) list(status = 1L, stdout = "", stderr = "Sin distribucion"),
                       .package = "processx")
  runner <- tempfile(fileext = ".py")
  file.create(runner)
  on.exit(unlink(runner), add = TRUE)
  expect_error(.ica_run_python("python3", runner, character(), "input", 120), "Sin distribucion")
})
