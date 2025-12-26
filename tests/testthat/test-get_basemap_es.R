test_that("get_basemap_es devuelve la estructura esperada", {
  
  # Polígono mínimo que cubre Península + Canarias
  basemap_polygon_sf <- st_as_sf(
    data.frame(id = 1),
    geometry = st_sfc(
      st_polygon(list(rbind(
        c(-20, 25),
        c( 10, 25),
        c( 10, 45),
        c(-20, 45),
        c(-20, 25)
      )))
    ),
    crs = 4326
  )
  
  local_mocked_bindings(
    gisco_get_countries = function(country, resolution) basemap_polygon_sf,
    .package = "metagesToolkit"
  )
  
  res <- get_basemap_es()
  
  expect_type(res, "list")
  expect_named(
    res,
    c("vecinos", "ES_fixed", "bb_fixed", "bb_can", "shift")
  )
  
  expect_s3_class(res$vecinos, "sf")
  expect_s3_class(res$ES_fixed, "sf")
  expect_s3_class(res$bb_fixed, "bbox")
  expect_s3_class(res$bb_can, "bbox")
})


test_that("get_basemap_es devuelve el shift usado", {
  
  basemap_polygon_sf <- st_as_sf(
    data.frame(id = 1),
    geometry = st_sfc(
      st_polygon(list(rbind(
        c(-20, 25),
        c( 10, 25),
        c( 10, 45),
        c(-20, 45),
        c(-20, 25)
      )))
    ),
    crs = 4326
  )
  
  local_mocked_bindings(
    gisco_get_countries = function(country, resolution) basemap_polygon_sf,
    .package = "metagesToolkit"
  )
  
  shift_val <- c(10, 20)
  res <- get_basemap_es(shift = shift_val)
  
  expect_equal(res$shift, shift_val)
})


test_that("get_basemap_es desplaza Canarias respecto a la Península", {
  
  # Dos polígonos: uno península, uno canarias
  ES <- st_as_sf(
    data.frame(
      region = c("main", "can")
    ),
    geometry = st_sfc(
      st_polygon(list(rbind(
        c(-9, 36),
        c( 4, 36),
        c( 4, 43),
        c(-9, 43),
        c(-9, 36)
      ))),
      st_polygon(list(rbind(
        c(-18, 28),
        c(-13, 28),
        c(-13, 32),
        c(-18, 32),
        c(-18, 28)
      )))
    ),
    crs = 4326
  )
  
  local_mocked_bindings(
    gisco_get_countries = function(country, resolution) ES,
    .package = "metagesToolkit"
  )
  
  res <- get_basemap_es(shift = c(5, 6))
  
  bb_can   <- res$bb_can
  bb_fixed <- res$bb_fixed
  
  # El bbox de Canarias desplazadas debe quedar dentro del bbox final
  expect_true(bb_can["xmin"] >= bb_fixed["xmin"])
  expect_true(bb_can["ymin"] >= bb_fixed["ymin"])
})
