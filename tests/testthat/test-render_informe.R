test_that("render_informe crea informe_output con reports/informe.docx", {
  
  withr::local_tempdir()
  old_wd <- getwd()
  setwd(tempdir())
  on.exit(setwd(old_wd), add = TRUE)
  
  testthat::local_mocked_bindings(
    quarto_render = function(input, output_format) {
      writeLines(
        "docx fake",
        file.path(dirname(input), "informe.docx")
      )
    },
    .package = "quarto"
  )
  
  res <- render_informe()
  
  expect_true(dir.exists("informe_output"))
  expect_true(dir.exists(file.path("informe_output", "reports")))
  expect_true(file.exists(
    file.path("informe_output", "reports", "informe.docx")
  ))
  
  expect_true(is.character(res))
})



test_that("render_informe falla si informe_output existe y overwrite = FALSE", {
  
  withr::local_tempdir()
  old_wd <- getwd()
  setwd(tempdir())
  on.exit(setwd(old_wd), add = TRUE)
  
  dir.create("informe_output")
  
  testthat::local_mocked_bindings(
    quarto_render = function(input, output_format) {
      writeLines(
        "docx fake",
        file.path(dirname(input), "informe.docx")
      )
    },
    .package = "quarto"
  )
  
  expect_error(
    render_informe(overwrite = FALSE),
    "overwrite = FALSE"
  )
})



test_that("render_informe llama a quarto_render con informe.qmd", {
  
  withr::local_tempdir()
  old_wd <- getwd()
  setwd(tempdir())
  on.exit(setwd(old_wd), add = TRUE)
  
  called_input <- NULL
  
  testthat::local_mocked_bindings(
    quarto_render = function(input, output_format) {
      called_input <<- input
      writeLines(
        "docx fake",
        file.path(dirname(input), "informe.docx")
      )
    },
    .package = "quarto"
  )
  
  render_informe()
  
  expect_true(grepl("informe.qmd$", called_input))
})
