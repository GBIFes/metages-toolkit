test_that("crear_mapa devuelve una lista con plot y data_map", {
  
  res <- crear_mapa(
    data = test_data,
    basemap = test_basemap,
    legend_params = test_legend_params
  )
  
  expect_type(res, "list")
  expect_named(res, c("plot", "data_map"))
  expect_s3_class(res$plot, "ggplot")
  expect_s3_class(res$data_map, "data.frame")
})



test_that("crear_mapa filtra por tipo_coleccion", {
  
  res <- crear_mapa(
    data = test_data,
    basemap = test_basemap,
    legend_params = test_legend_params,
    tipo_coleccion = "coleccion"
  )
  
  expect_true(all(res$data_map$tipo_body == "coleccion"))
})



test_that("crear_mapa filtra por publican", {
  
  res <- crear_mapa(
    data = test_data,
    basemap = test_basemap,
    legend_params = test_legend_params,
    publican = TRUE
  )
  
  expect_true(all(res$data_map$publica_en_gbif))
})



test_that("crear_mapa elimina NA en facet cuando facet no es NULL", {
  
  res <- crear_mapa(
    data = test_data,
    basemap = test_basemap,
    legend_params = test_legend_params,
    facet = "facet_var"
  )
  
  expect_false(any(is.na(res$data_map$facet_var)))
})



test_that("crear_mapa falla con tipo_coleccion invalido", {
  
  expect_error(
    crear_mapa(
      data = test_data,
      basemap = test_basemap,
      tipo_coleccion = "otra"
    )
  )
})



test_that("crear_mapa falla con publican invalido", {
  
  expect_error(
    crear_mapa(
      data = test_data,
      basemap = test_basemap,
      publican = 1
    ),
    "TRUE, FALSE or NULL"
  )
})



test_that("crear_mapa falla con facet inexistente", {
  
  expect_error(
    crear_mapa(
      data = test_data,
      basemap = test_basemap,
      facet = "no_existe"
    ),
    "column name"
  )
})


