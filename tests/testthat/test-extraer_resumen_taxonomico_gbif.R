test_that("estructura correcta y fila Total al final", {
  
  mock_occ_count <- function(taxonKey = NULL,
                             publishingCountry = NULL,
                             occurrenceStatus = NULL,
                             basisOfRecord = NULL,
                             facet = NULL,
                             facetLimit = NULL) {
    
    # Sin facet → devuelve número total de registros
    if (is.null(facet)) {
      return(100)
    }
    
    # Con facet → devolver data.frame simulado
    data.frame(
      key = 1:3,
      count = c(10, 20, 30)
    )
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    {
      res <- extraer_resumen_taxonomico_gbif()
    }
  )
  
  # 8 reinos + Total
  expect_equal(nrow(res), 9)
  
  expect_true("Reino" %in% names(res))
  expect_true("Nº registros" %in% names(res))
  
  expect_equal(res$Reino[9], "Total")
})

# ------------------------------------------------------------

test_that("calcula correctamente la suma Total", {
  
  mock_occ_count <- function(taxonKey = NULL,
                             publishingCountry = NULL,
                             occurrenceStatus = NULL,
                             basisOfRecord = NULL,
                             facet = NULL,
                             facetLimit = NULL) {
    
    if (is.null(facet)) {
      return(10)  # 10 registros por reino
    }
    
    data.frame(
      key = 1:2,
      count = c(1, 2)
    )
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    {
      res <- extraer_resumen_taxonomico_gbif()
    }
  )
  
  # 8 reinos * 10 registros = 80
  expect_equal(res$`Nº registros`[9], "80")
})

# ------------------------------------------------------------

test_that("formatea miles con punto", {
  
  mock_occ_count <- function(taxonKey = NULL,
                             publishingCountry = NULL,
                             occurrenceStatus = NULL,
                             basisOfRecord = NULL,
                             facet = NULL,
                             facetLimit = NULL) {
    
    if (is.null(facet)) {
      return(1234567)
    }
    
    data.frame(key = 1, count = 1)
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    {
      res <- extraer_resumen_taxonomico_gbif()
    }
  )
  
  expect_match(res$`Nº registros`[1], "1\\.234\\.567")
})

# ------------------------------------------------------------

test_that("trimws elimina espacios", {
  
  mock_occ_count <- function(taxonKey = NULL,
                             publishingCountry = NULL,
                             occurrenceStatus = NULL,
                             basisOfRecord = NULL,
                             facet = NULL,
                             facetLimit = NULL) {
    
    if (is.null(facet)) {
      return(1)
    }
    
    data.frame(key = 1, count = 1)
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    {
      res <- extraer_resumen_taxonomico_gbif()
    }
  )
  
  expect_false(any(grepl("^\\s|\\s$", res$Reino)))
})

# ------------------------------------------------------------

test_that("basisOfRecord se pasa correctamente a occ_count", {
  
  captured_basis <- NULL
  
  mock_occ_count <- function(taxonKey = NULL,
                             publishingCountry = NULL,
                             occurrenceStatus = NULL,
                             basisOfRecord = NULL,
                             facet = NULL,
                             facetLimit = NULL) {
    
    captured_basis <<- basisOfRecord
    
    if (is.null(facet)) {
      return(1)
    }
    
    data.frame(key = 1, count = 1)
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    {
      extraer_resumen_taxonomico_gbif(
        basisOfRecord = c("A", "B")
      )
    }
  )
  
  expect_equal(captured_basis, "A;B")
})

# ------------------------------------------------------------

test_that("funciona si basisOfRecord es NULL", {
  
  mock_occ_count <- function(taxonKey = NULL,
                             publishingCountry = NULL,
                             occurrenceStatus = NULL,
                             basisOfRecord = NULL,
                             facet = NULL,
                             facetLimit = NULL) {
    
    if (is.null(facet)) {
      return(5)
    }
    
    data.frame(key = 1, count = 1)
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    {
      res <- extraer_resumen_taxonomico_gbif()
    }
  )
  
  expect_equal(nrow(res), 9)
})