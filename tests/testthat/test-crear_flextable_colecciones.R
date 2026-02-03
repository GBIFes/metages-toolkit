test_that("crear_flextable_colecciones devuelve flextable", {
  
  tabla <- tibble::tibble(
    institucion_proyecto = "Museo X",
    url_institucion = "https://museo.example",
    coleccion_base = "Colección",
    coleccion_url = "https://coleccion.example"
  )
  
  ft <- crear_flextable_colecciones(tabla)
  
  expect_s3_class(ft, "flextable")
})
