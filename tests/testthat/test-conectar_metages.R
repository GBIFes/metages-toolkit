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
