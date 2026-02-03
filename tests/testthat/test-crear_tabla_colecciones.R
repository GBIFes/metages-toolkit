test_that("crear_tabla_colecciones aplica filtro por subdisciplina", {
  
  fake_colecciones <- function() {
    list(
      data = tibble::tibble(
        disciplina_def = "Zoológica",
        disciplina_subtipo_def = "Invertebrados",
        institucion_proyecto = "Museo X",
        url_institucion = "https://museo.example",
        coleccion_base = "Colección A",
        coleccion_url = "https://coleccion.example",
        collection_code = "COL",
        town = "Madrid",
        region = "Madrid",
        number_of_subunits = 1,
        ultima_actualizacion_coleccion = 2024,
        fecha_alta_coleccion = 2020,
        numberOfRecords = 1,
        ultima_actualizacion_recursos = 2023,
        percent_database = 50,
        percent_georref = 50,
        tipo_body = "coleccion"
      )
    )
  }
  
  local_mocked_bindings(
    extraer_colecciones_mapa = fake_colecciones,
    .package = "metagesToolkit"
  )
  
  out <- crear_tabla_colecciones(list(subdisciplina = "Invertebrados"))
  
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 1)
})
