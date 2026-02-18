# tests/testthat/test-extraer_tipos_recursos_ipt_pais.R

library(testthat)

mock_api_call <- function(mock_json_list) {
  
  call_index <- 0
  
  mock_get <- function(...) {
    structure(list(), class = "response")
  }
  
  mock_stop <- function(...) NULL
  
  mock_content <- function(...) {
    "{}"  # content is irrelevant because we override fromJSON
  }
  
  mock_fromjson <- function(...) {
    call_index <<- call_index + 1
    mock_json_list[[call_index]]
  }
  
  with_mocked_bindings(
    GET = mock_get,
    stop_for_status = mock_stop,
    content = mock_content,
    fromJSON = mock_fromjson,
    .package = "metagesToolkit",
    {
      extraer_tipos_recursos_ipt_pais("ES")
    }
  )
}

# --------------------------------------------------
# Basic structure
# --------------------------------------------------

test_that("estructura correcta con un tipo", {
  
  mock_json <- list(
    list(count = 1, results = list(list(type="OCCURRENCE", recordCount=100))),
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 0, results = list())
  )
  
  res <- mock_api_call(mock_json)
  
  expect_s3_class(res, "data.frame")
  expect_true(all(c(
    "Tipo de juego de datos",
    "Nº de recursos",
    "Nº de registros publicados"
  ) %in% names(res)))
})

# --------------------------------------------------
# Totals
# --------------------------------------------------

test_that("calcula correctamente totales", {
  
  mock_json <- list(
    list(count = 2, results = list(
      list(type="OCCURRENCE", recordCount=100),
      list(type="OCCURRENCE", recordCount=200)
    )),
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 0, results = list())
  )
  
  res <- mock_api_call(mock_json)
  
  total <- res[res$`Tipo de juego de datos`=="TOTAL",]
  occ   <- res[res$`Tipo de juego de datos`=="Occurrence",]
  
  expect_equal(occ$`Nº de recursos`, 2)
  expect_equal(occ$`Nº de registros publicados`, 300)
  expect_equal(total$`Nº de recursos`, 2)
  expect_equal(total$`Nº de registros publicados`, 300)
})

# --------------------------------------------------
# NA handling
# --------------------------------------------------

test_that("NA recordCount se convierte en 0", {
  
  mock_json <- list(
    list(count = 1, results = list(
      list(type="METADATA", recordCount=NA)
    )),
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 0, results = list())
  )
  
  res <- mock_api_call(mock_json)
  
  meta <- res[res$`Tipo de juego de datos`=="Metadata",]
  expect_equal(meta$`Nº de registros publicados`, 0)
})

# --------------------------------------------------
# Type formatting
# --------------------------------------------------

test_that("formatea correctamente SAMPLING_EVENT", {
  
  mock_json <- list(
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 1, results = list(
      list(type="SAMPLING_EVENT", recordCount=10)
    )),
    list(count = 0, results = list())
  )
  
  res <- mock_api_call(mock_json)
  
  expect_true("Sampling Event" %in% res$`Tipo de juego de datos`)
})

# --------------------------------------------------
# Pagination
# --------------------------------------------------

test_that("maneja paginación por tipo", {
  
  mock_json <- list(
    list(count = 2, results = list(
      list(type="OCCURRENCE", recordCount=100)
    )),
    list(count = 2, results = list(
      list(type="OCCURRENCE", recordCount=200)
    )),
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 0, results = list())
  )
  
  res <- mock_api_call(mock_json)
  
  occ <- res[res$`Tipo de juego de datos`=="Occurrence",]
  
  expect_equal(occ$`Nº de recursos`, 2)
  expect_equal(occ$`Nº de registros publicados`, 300)
})

# --------------------------------------------------
# Empty case
# --------------------------------------------------

test_that("devuelve data.frame vacío si no hay datos", {
  
  mock_json <- list(
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 0, results = list()),
    list(count = 0, results = list())
  )
  
  res <- mock_api_call(mock_json)
  
  expect_equal(nrow(res), 0)
})