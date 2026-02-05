test_that("crear_tabla_colecciones aplica filtro por subdisciplina", {
  
  test_data <- tibble::tibble(
    disciplina_def = c("Zoológica", "Zoológica"),
    disciplina_subtipo_def = c("Invertebrados", "Vertebrados"),
    institucion_proyecto = c("Inst A", "Inst B"),
    url_institucion = c("u1", "u2"),
    coleccion_base = c("Col A", "Col B"),
    coleccion_url = c("c1", "c2"),
    collection_code = c("A", "B"),
    town = c("Madrid", "Madrid"),
    region = c("Madrid", "Madrid"),
    number_of_subunits = c(10, 20),
    numberOfRecords = c(100, 200),
    percent_database = c(50, 60),
    percent_georref = c(70, 80),
    tipo_body = c("coleccion", "coleccion"),
    ultima_actualizacion_coleccion = c(2020, 2021),
    fecha_alta_coleccion = c(2019, 2019),
    ultima_actualizacion_recursos = c(2022, 2022)
  )
  
  testthat::local_mocked_bindings(
    extraer_colecciones_mapa = function(..., odbc_driver = NULL) {
      list(data = test_data)
    },
    .package = "metagesToolkit"
  )
  
  res <- crear_tabla_colecciones(
    filtro = list(subdisciplina = "Invertebrados")
  )
  
  expect_equal(nrow(res), 1)
})
