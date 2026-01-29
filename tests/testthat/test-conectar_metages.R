test_that("conectar_metages falla si faltan variables de entorno", {
  
  old <- Sys.getenv(c(
    "host_prod",
    "keyfile",
    "prod_ssh_bridge_R",
    "Database",
    "UID",
    "gbif_wp_pass"
  ))
  
  Sys.setenv(
    host_prod = "",
    keyfile = "",
    prod_ssh_bridge_R = "",
    Database = "",
    UID = "",
    gbif_wp_pass = ""
  )
  
  on.exit(do.call(Sys.setenv, as.list(old)), add = TRUE)
  
  expect_error(
    conectar_metages(),
    "Missing required environment variables"
  )
})


test_that("conectar_metages falla si el driver ODBC no existe", {
  
  Sys.setenv(
    host_prod = "dummy",
    keyfile = "dummy",
    prod_ssh_bridge_R = "ssh dummy",
    Database = "dummy",
    UID = "dummy",
    gbif_wp_pass = "dummy"
  )
  
  testthat::with_mocked_bindings(
    
    odbcListDrivers = function() {
      data.frame(name = c("Driver A", "Driver B"))
    },
    
    expect_error(
      conectar_metages(driver = "Driver inexistente"),
      "ODBC driver not found"
    )
  )
})


test_that("conectar_metages no intenta abrir SSH si falla antes", {
  
  Sys.setenv(
    host_prod = "",
    keyfile = "",
    prod_ssh_bridge_R = "",
    Database = "",
    UID = "",
    gbif_wp_pass = ""
  )
  
  testthat::with_mocked_bindings(
    
    ssh_connect = function(...) {
      stop("ssh_connect no debería ser llamado")
    },
    
    expect_error(
      conectar_metages(),
      "Missing required environment variables"
    )
  )
})
