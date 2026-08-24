test_that("conectar_metages usa produccion por defecto", {
  withr::local_envvar(c(
    host_prod = "prod.example.org",
    host_test = "test.example.org",
    keyfile = "dummy-key",
    prod_ssh_bridge_R = "-N prod-bridge",
    test_ssh_bridge_R = "-N test-bridge",
    Database = "dummy-db",
    UID = "dummy-user",
    gbif_wp_pass = "prod-password",
    gbif_wp_pass_test = "test-password"
  ))

  observed <- new.env(parent = emptyenv())

  testthat::local_mocked_bindings(
    odbcListDrivers = function(...) {
      data.frame(name = "MySQL ODBC 9.4 Unicode Driver")
    },
    .package = "odbc"
  )
  testthat::local_mocked_bindings(
    ssh_connect = function(host, keyfile, ...) {
      observed$host <- host
      observed$keyfile <- keyfile
      "dummy-session"
    },
    .package = "ssh"
  )
  testthat::local_mocked_bindings(
    odbc = function(...) "dummy-driver",
    process = list(
      new = function(command, args, supervise, ...) {
        observed$command <- command
        observed$bridge_args <- args
        list(is_alive = function() TRUE)
      }
    ),
    dbConnect = function(drv, ...) {
      observed$db_args <- list(...)
      "dummy-connection"
    },
    .package = "metagesToolkit"
  )

  result <- conectar_metages()

  expect_equal(observed$host, "prod.example.org")
  expect_equal(observed$bridge_args, c("-N", "prod-bridge"))
  expect_equal(observed$db_args$PWD, "prod-password")
  expect_equal(result$con, "dummy-connection")
})


test_that("conectar_metages usa las variables del entorno de test", {
  withr::local_envvar(c(
    host_prod = "prod.example.org",
    host_test = "test.example.org",
    keyfile = "dummy-key",
    prod_ssh_bridge_R = "-N prod-bridge",
    test_ssh_bridge_R = "-N test-bridge",
    Database = "dummy-db",
    UID = "dummy-user",
    gbif_wp_pass = "prod-password",
    gbif_wp_pass_test = "test-password"
  ))

  observed <- new.env(parent = emptyenv())

  testthat::local_mocked_bindings(
    odbcListDrivers = function(...) {
      data.frame(name = "MySQL ODBC 9.4 Unicode Driver")
    },
    .package = "odbc"
  )
  testthat::local_mocked_bindings(
    ssh_connect = function(host, keyfile, ...) {
      observed$host <- host
      "dummy-session"
    },
    .package = "ssh"
  )
  testthat::local_mocked_bindings(
    odbc = function(...) "dummy-driver",
    process = list(
      new = function(command, args, supervise, ...) {
        observed$bridge_args <- args
        list(is_alive = function() TRUE)
      }
    ),
    dbConnect = function(drv, ...) {
      observed$db_args <- list(...)
      "dummy-connection"
    },
    .package = "metagesToolkit"
  )

  conectar_metages(entorno = "test")

  expect_equal(observed$host, "test.example.org")
  expect_equal(observed$bridge_args, c("-N", "test-bridge"))
  expect_equal(observed$db_args$PWD, "test-password")
})


test_that("conectar_metages valida las variables del entorno seleccionado", {
  withr::local_envvar(c(
    host_prod = "",
    host_test = "test.example.org",
    keyfile = "dummy-key",
    prod_ssh_bridge_R = "",
    test_ssh_bridge_R = "-N test-bridge",
    Database = "dummy-db",
    UID = "dummy-user",
    gbif_wp_pass = "",
    gbif_wp_pass_test = "test-password"
  ))

  expect_error(
    conectar_metages(),
    "host_prod, prod_ssh_bridge_R, gbif_wp_pass",
    fixed = TRUE
  )

  withr::local_envvar(c(
    host_prod = "prod.example.org",
    host_test = "",
    prod_ssh_bridge_R = "-N prod-bridge",
    test_ssh_bridge_R = "",
    gbif_wp_pass = "prod-password",
    gbif_wp_pass_test = ""
  ))

  expect_error(
    conectar_metages(entorno = "test"),
    "host_test, test_ssh_bridge_R, gbif_wp_pass_test",
    fixed = TRUE
  )
})


test_that("conectar_metages rechaza entornos desconocidos antes de conectar", {
  testthat::local_mocked_bindings(
    ssh_connect = function(...) {
      stop("ssh_connect no deberia ser llamado")
    },
    .package = "ssh"
  )

  expect_error(
    conectar_metages(entorno = "staging"),
    "prod.*test"
  )
})


test_that("conectar_metages falla si el driver ODBC no existe", {
  withr::local_envvar(c(
    host_prod = "dummy",
    keyfile = "dummy",
    prod_ssh_bridge_R = "ssh dummy",
    Database = "dummy",
    UID = "dummy",
    gbif_wp_pass = "dummy"
  ))

  testthat::local_mocked_bindings(
    odbcListDrivers = function(...) {
      data.frame(name = c("Driver A", "Driver B"))
    },
    .package = "odbc"
  )

  expect_error(
    conectar_metages(driver = "Driver inexistente"),
    "ODBC driver not found"
  )
})
