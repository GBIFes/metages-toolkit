test_that("falla si no existe metagesToolkit.last_docx", {
  
  withr::local_options(metagesToolkit.last_docx = NULL)
  
  expect_error(
    insertar_tablas_colecciones("Colecciones", list(list())),
    "Ejecute primero render_informe"
  )
})



test_that("flujo completo devuelve la ruta final del docx", {
  
  tmp_docx <- tempfile(fileext = ".docx")
  file.create(tmp_docx)
  
  withr::local_options(metagesToolkit.last_docx = tmp_docx)
  
  fake_colecciones <- function() {
    list(
      data = tibble::tibble(
        institucion_proyecto = "Museo X",
        url_institucion = "https://museo.example",
        coleccion_base = "Herbario",
        coleccion_url = "https://herbario.example",
        collection_code = "HB",
        town = "Madrid",
        region = "Madrid",
        number_of_subunits = 1000,
        ultima_actualizacion_coleccion = 2024,
        fecha_alta_coleccion = 2020,
        numberOfRecords = 500,
        ultima_actualizacion_recursos = 2023,
        percent_database = 80,
        percent_georref = 70,
        tipo_body = "coleccion"
      )
    )
  }
  
  local_mocked_bindings(
    extraer_colecciones_mapa = fake_colecciones,
    .package = "metagesToolkit"
  )
  
  local_mocked_bindings(
    read_docx = function(path) "doc",
    cursor_reach = function(doc, keyword) doc,
    body_end_section_portrait = function(doc) doc,
    body_end_section_landscape = function(doc) doc,
    .package = "officer"
  )
  
  local_mocked_bindings(
    flextable = function(x) "ft",
    compose = function(...) "ft",
    delete_columns = function(ft, j) ft,
    set_header_labels = function(ft, ...) ft,
    body_add_flextable = function(doc, value, align) doc,
    .package = "flextable"
  )
  
  local_mocked_bindings(
    print = function(x, target) invisible(target),
    .package = "base"
  )
  
  out <- insertar_tablas_colecciones(
    keywords = "Colecciones",
    filtros = list(list())
  )
  
  expect_true(grepl("_tablas_colecciones\\.docx$", out))
})
