test_that("extraer_colecciones_mapa devuelve data, con y tunnel", {
  
  local_mocked_bindings(
    conectar_metages = function() {
      list(con = "fake_con", tunnel = NULL)
    },
    dbGetQuery = function(con, query) {
      test_data
    },
    .package = "metagesToolkit"
  )
  
  res <- extraer_colecciones_mapa()
  
  expect_type(res, "list")
  expect_named(res, c("data", "con", "tunnel"))
  expect_s3_class(res$data, "data.frame")
})



test_that("extraer_colecciones_mapa elimina town NA o vacíos", {
  
  local_mocked_bindings(
    conectar_metages = function() list(con = "fake", tunnel = NULL),
    dbGetQuery = function(con, query) test_data,
    .package = "metagesToolkit"
  )
  
  res <- extraer_colecciones_mapa()
  
  expect_false(any(is.na(res$data$town)))
  expect_false(any(trimws(res$data$town) == ""))
})



test_that("extraer_colecciones_mapa convierte latitude y longitude a numeric", {
  
  local_mocked_bindings(
    conectar_metages = function() list(con = "fake", tunnel = NULL),
    dbGetQuery = function(con, query) test_data,
    .package = "metagesToolkit"
  )
  
  res <- extraer_colecciones_mapa()
  
  expect_type(res$data$latitude, "double")
  expect_type(res$data$longitude, "double")
})



test_that("extraer_colecciones_mapa aplica shift a Canarias", {
  
  local_mocked_bindings(
    conectar_metages = function() list(con = "fake", tunnel = NULL),
    dbGetQuery = function(con, query) test_data,
    .package = "metagesToolkit"
  )
  
  res <- extraer_colecciones_mapa(shift = c(5, 6))
  
  can <- res$data |>
    dplyr::filter(longitude < -10 & latitude < 34)
  
  expect_true(all(can$longitude_adj == can$longitude + 5))
  expect_true(all(can$latitude_adj  == can$latitude + 6))
})



test_that("extraer_colecciones_mapa no cierra la conexión por defecto", {
  
  closed <- FALSE
  
  local_mocked_bindings(
    conectar_metages = function() {
      list(con = "fake_con", tunnel = NULL)
    },
    dbGetQuery = function(con, query) test_data,
    dbDisconnect = function(con) {
      closed <<- TRUE
    },
    .package = "metagesToolkit"
  )
  
  extraer_colecciones_mapa()
  
  expect_false(closed)
})



test_that("extraer_colecciones_mapa cierra la conexión si cerrar_conexion = TRUE", {
  
  closed <- FALSE
  
  local_mocked_bindings(
    conectar_metages = function() {
      list(con = "fake_con", tunnel = NULL)
    },
    dbGetQuery = function(con, query) test_data,
    dbDisconnect = function(con) {
      closed <<- TRUE
    },
    .package = "metagesToolkit"
  )
  
  extraer_colecciones_mapa(cerrar_conexion = TRUE)
  
  expect_true(closed)
})
