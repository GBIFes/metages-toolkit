library(testthat)

# ------------------------------------------------------------------

test_that("estructura correcta y TOTAL al final", {
  
  mock_occ_count <- function(...) {
    data.frame(
      phylumKey = c("1", "2"),
      count = c(1000, 2000),
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    key <- sub(".*/", "", req$url)
    list(canonicalName = ifelse(key == "1", "A", "B"))
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon()
      
      expect_true(is.data.frame(res))
      expect_equal(names(res), c("Filo", "Nº registros"))
      expect_equal(nrow(res), 3)
      expect_equal(res[[1]][3], "TOTAL")
    }
  )
})

# ------------------------------------------------------------------

test_that("nombre dinamico segun facet", {
  
  mock_occ_count <- function(...) {
    data.frame(
      classKey = c("1", "2"),
      count = c(10, 20),
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    list(canonicalName = "X")
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon(facet = "classKey")
      expect_equal(names(res)[1], "Clase")
    }
  )
})

# ------------------------------------------------------------------

test_that("fallback para facet no definido en etiquetas", {
  
  mock_occ_count <- function(...) {
    data.frame(
      subclassKey = "1",
      count = 10,
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    list(canonicalName = "X")
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon(facet = "subclassKey")
      expect_equal(names(res)[1], "Subclass")
    }
  )
})

# ------------------------------------------------------------------

test_that("ordena descendente antes de TOTAL", {
  
  mock_occ_count <- function(...) {
    data.frame(
      phylumKey = c("1", "2"),
      count = c(500, 1000),
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    key <- sub(".*/", "", req$url)
    list(canonicalName = ifelse(key == "1", "A", "B"))
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon()
      expect_equal(res[[1]][1], "B")
      expect_equal(res[[1]][3], "TOTAL")
    }
  )
})

# ------------------------------------------------------------------

test_that("formatea numeros con punto como separador", {
  
  mock_occ_count <- function(...) {
    data.frame(
      phylumKey = "1",
      count = 1234567,
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    list(canonicalName = "A")
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon()
      expect_match(res$`Nº registros`[1], "1\\.234\\.567")
    }
  )
})

# ------------------------------------------------------------------

test_that("trimws elimina espacios en ambas columnas", {
  
  mock_occ_count <- function(...) {
    data.frame(
      phylumKey = "1",
      count = 10,
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    list(canonicalName = "  Arthropoda  ")
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon()
      expect_equal(res[[1]][1], "Arthropoda")
      expect_false(grepl("^\\s|\\s$", res[[1]][1]))
      expect_false(grepl("^\\s|\\s$", res$`Nº registros`[1]))
    }
  )
})

# ------------------------------------------------------------------

test_that("argumentos se pasan correctamente a occ_count", {
  
  captured <- list()
  
  mock_occ_count <- function(...) {
    captured <<- list(...)
    data.frame(
      phylumKey = "1",
      count = 10,
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    list(canonicalName = "A")
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      conteo_registros_por_taxon(
        taxonKey = 6,
        facet = "phylumKey",
        basisOfRecord = c("HUMAN_OBSERVATION")
      )
    }
  )
  
  expect_equal(captured$taxonKey, 6)
  expect_equal(captured$facet, "phylumKey")
  expect_equal(captured$basisOfRecord, "HUMAN_OBSERVATION")
})

# ------------------------------------------------------------------

test_that("funciona con un solo taxon agregado", {
  
  mock_occ_count <- function(...) {
    data.frame(
      phylumKey = "1",
      count = 10,
      stringsAsFactors = FALSE
    )
  }
  
  mock_species <- function(req) {
    list(canonicalName = "Solo")
  }
  
  with_mocked_bindings(
    occ_count = mock_occ_count,
    request = function(url) structure(list(url = url), class = "mock_request"),
    req_perform = function(req) req,
    resp_body_json = mock_species,
    {
      res <- conteo_registros_por_taxon()
      expect_equal(nrow(res), 2)
      expect_equal(res[[1]][1], "Solo")
      expect_equal(res[[1]][2], "TOTAL")
    }
  )
})