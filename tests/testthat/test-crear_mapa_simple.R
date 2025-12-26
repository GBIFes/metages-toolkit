test_that("crear_mapa_simple devuelve plot y data_map", {
  
  local_mocked_bindings(
    extraer_colecciones_mapa = function() list(data = test_data),
    get_basemap_es = function() test_basemap,
    compute_legend_params = function(data) test_legend_params,
    .package = "metagesToolkit"
  )
  
  res <- crear_mapa_simple()
  
  expect_type(res, "list")
  expect_named(res, c("plot", "data_map"))
  expect_s3_class(res$plot, "ggplot")
  expect_s3_class(res$data_map, "data.frame")
})




test_that("crear_mapa_simple pasa filtros a crear_mapa", {
  
  local_mocked_bindings(
    extraer_colecciones_mapa = function() list(data = test_data),
    get_basemap_es = function() test_basemap,
    compute_legend_params = function(data) test_legend_params,
    .package = "metagesToolkit"
  )
  
  res <- crear_mapa_simple(disciplina = "Zoológica")
  
  expect_true(all(res$data_map$disciplina_def == "Zoológica"))
})




test_that("crear_mapa_simple falla si crear_mapa falla", {
  
  local_mocked_bindings(
    extraer_colecciones_mapa = function() list(data = test_data),
    get_basemap_es = function() test_basemap,
    compute_legend_params = function(data) test_legend_params,
    .package = "metagesToolkit"
  )
  
  expect_error(
    crear_mapa_simple(tipo_coleccion = "otra")
  )
})

