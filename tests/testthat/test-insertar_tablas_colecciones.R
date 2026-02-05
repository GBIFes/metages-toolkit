test_that("falla si no existe metagesToolkit.last_docx", {
  
  withr::local_options(metagesToolkit.last_docx = NULL)
  
  expect_error(
    insertar_tablas_colecciones("Colecciones", list(list())),
    "Ejecute primero render_informe"
  )
})

test_that("flujo completo devuelve la ruta final del docx", {
  
  withr::local_tempdir()
  old_wd <- getwd()
  setwd(tempdir())
  on.exit(setwd(old_wd), add = TRUE)
  
  fake_docx <- file.path(getwd(), "fake.docx")
  file.create(fake_docx)
  options(metagesToolkit.last_docx = fake_docx)
  
  # ---- mocks del paquete metagesToolkit ----
  testthat::local_mocked_bindings(
    crear_tabla_colecciones = function(filtro, driver = NULL) {
      data.frame(
        institucion_proyecto = "Inst",
        coleccion_base = "Col",
        Tipo = "CB"
      )
    },
    crear_flextable_colecciones = function(x) x,
    insertar_tabla_en_doc = function(doc, keyword, ft) doc,
    .package = "metagesToolkit"
  )
  
  # ---- mockear officer ----
  testthat::local_mocked_bindings(
    read_docx = function(path) "doc",
    .package = "officer"
  )
  
  # ---- mockear escritura final ----
  testthat::local_mocked_bindings(
    print = function(x, target) invisible(target),
    .package = "base"
  )
  
  res <- insertar_tablas_colecciones(
    keywords = "Colecciones",
    filtros  = list(list()),
    driver   = "MySQL ODBC 9.4 Unicode Driver"
  )
  
  expect_true(is.character(res))
  expect_true(grepl("_tablas_colecciones\\.docx$", res))
})
