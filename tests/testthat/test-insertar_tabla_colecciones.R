test_that("falla si no existe metagesToolkit.last_docx", {
  withr::local_options(metagesToolkit.last_docx = NULL)
  
  expect_error(
    insertar_tabla_colecciones("Colecciones"),
    "No se encuentra un informe renderizado"
  )
})


test_that("falla si la ruta del docx no existe", {
  withr::local_options(
    metagesToolkit.last_docx = tempfile(fileext = ".docx")
  )
  
  expect_error(
    insertar_tabla_colecciones("Colecciones"),
    "No se encuentra un informe renderizado"
  )
})


test_that("flujo completo mockeado devuelve la ruta final del docx", {
  
  # ---- preparar docx temporal ----
  tmp_docx <- tempfile(fileext = ".docx")
  file.create(tmp_docx)
  
  withr::local_options(
    metagesToolkit.last_docx = tmp_docx
  )
  
  # ---- datos fake ----
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
  
  # ---- mock función interna ----
  testthat::local_mocked_bindings(
    extraer_colecciones_mapa = fake_colecciones,
    .package = "metagesToolkit"
  )
  
  # ---- mocks officer ----
  testthat::local_mocked_bindings(
    read_docx = function(path) "doc",
    cursor_reach = function(doc, keyword) doc,
    body_end_section_portrait = function(doc) doc,
    body_end_section_landscape = function(doc) doc,
    .package = "officer"
  )
  
  # ---- mocks flextable ----
  testthat::local_mocked_bindings(
    flextable = function(x) "ft",
    compose = function(...) "ft",
    delete_columns = function(ft, j) ft,
    set_header_labels = function(ft, ...) ft,
    body_add_flextable = function(doc, value, align) doc,
    .package = "flextable"
  )
  
  # ---- evitar escritura real ----
  testthat::local_mocked_bindings(
    print = function(x, target) invisible(target),
    .package = "base"
  )
  
  # ---- ejecutar ----
  out <- insertar_tabla_colecciones("Colecciones")
  
  # ---- comprobar ----
  expect_true(grepl("_con_tablas_colecciones\\.docx$", out))
})


test_that("el keyword se pasa correctamente a cursor_reach()", {
  
  tmp_docx <- tempfile(fileext = ".docx")
  file.create(tmp_docx)
  
  withr::local_options(
    metagesToolkit.last_docx = tmp_docx
  )
  
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
  
  testthat::local_mocked_bindings(
    extraer_colecciones_mapa = fake_colecciones,
    .package = "metagesToolkit"
  )
  
  called_keyword <- NULL
  
  testthat::local_mocked_bindings(
    read_docx = function(path) "doc",
    cursor_reach = function(doc, keyword) {
      called_keyword <<- keyword
      doc
    },
    body_end_section_portrait = function(doc) doc,
    body_end_section_landscape = function(doc) doc,
    .package = "officer"
  )
  
  
  testthat::local_mocked_bindings(
    flextable = function(x) "ft",
    compose = function(...) "ft",
    delete_columns = function(ft, j) ft,
    set_header_labels = function(ft, ...) ft,
    body_add_flextable = function(doc, value, align) doc,
    .package = "flextable"
  )
  
  testthat::local_mocked_bindings(
    print = function(x, target) invisible(target),
    .package = "base"
  )
  
  insertar_tabla_colecciones("MIS COLECCIONES")
  
  expect_identical(called_keyword, "MIS COLECCIONES")
})
