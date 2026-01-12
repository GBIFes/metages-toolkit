# tests/testthat/test-top_countries_gbif.R
# Tests internos para rankings GBIF por país
# (país de ocurrencia y país publicador)

# ============================================================
# Mocks
# ============================================================

mock_occ_count_country <- function() {
  tibble::tibble(
    iso2 = c("US", "GB", "DE", "FR", "ES", "CN", "BR", "IN", "JP", "IT", "CA"),
    count = c(100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 5)
  )
}

mock_occ_search <- function(facet,
                            year = NULL,
                            limit = NULL,
                            facetLimit = NULL,
                            occurrenceStatus = NULL,
                            ...) {
  
  stopifnot(facet %in% c("country", "publishingCountry"))
  
  tibble_facets <- tibble::tibble(
    name  = c("US", "GB", "DE", "FR", "ES"),
    count = c(500, 400, 300, 200, 100)
  )
  
  facets <- list()
  facets[[facet]] <- tibble_facets
  
  list(facets = facets)
}

# ============================================================
# Tests: get_top10_countries_rgbif()
# ============================================================

test_that("get_top10_countries_rgbif devuelve estructura esperada", {
  
  testthat::local_mocked_bindings(
    occ_count_country = mock_occ_count_country,
    occ_search        = mock_occ_search
  )
  
  res <- get_top10_countries_rgbif(years_back = 2)
  
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 10)
  
  expect_true(all(c(
    "pais",
    "iso2",
    "count",
    "posicion_prev_cum",
    "count_prev_cum"
  ) %in% names(res)))
})

test_that("get_top10_countries_rgbif funciona con distintos years_back", {
  
  testthat::local_mocked_bindings(
    occ_count_country = mock_occ_count_country,
    occ_search        = mock_occ_search
  )
  
  res1 <- get_top10_countries_rgbif(years_back = 1)
  res5 <- get_top10_countries_rgbif(years_back = 5)
  
  expect_equal(nrow(res1), 10)
  expect_equal(nrow(res5), 10)
  
  # Semántica correcta:
  # algunos países están en el ranking histórico, otros no
  expect_true(any(!is.na(res1$posicion_prev_cum)))
  expect_true(any(is.na(res1$posicion_prev_cum)))
  
  expect_true(any(!is.na(res5$posicion_prev_cum)))
  expect_true(any(is.na(res5$posicion_prev_cum)))
})

# ============================================================
# Tests: get_top_publishing_countries_gbif()
# ============================================================

test_that("get_top_publishing_countries_gbif devuelve estructura esperada", {
  
  testthat::local_mocked_bindings(
    occ_search = mock_occ_search
  )
  
  res <- suppressWarnings(
    get_top_publishing_countries_gbif(
      n = 3,
      years_back = 2
    )
  )
  
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 3)
  
  expect_true(all(c(
    "publishingCountry",
    "count",
    "pais_publicador",
    "posicion_prev_cum",
    "count_prev_cum"
  ) %in% names(res)))
})

test_that("get_top_publishing_countries_gbif respeta el argumento n", {
  
  testthat::local_mocked_bindings(
    occ_search = mock_occ_search
  )
  
  res <- suppressWarnings(
    get_top_publishing_countries_gbif(n = 2)
  )
  
  expect_equal(nrow(res), 2)
})

test_that("get_top_publishing_countries_gbif valida argumentos", {
  
  expect_error(
    get_top_publishing_countries_gbif(n = -1)
  )
  
  expect_error(
    get_top_publishing_countries_gbif(years_back = -2)
  )
  
  expect_error(
    get_top_publishing_countries_gbif(n = 0)
  )
})
