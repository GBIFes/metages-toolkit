# tests/testthat/test-crear_plots_evolucion_basisOfRecord.R

library(testthat)
library(dplyr)

# ============================================================
# MOCK DATA
# ============================================================

mock_datos_raw <- tibble::tibble(
  year = c("2000","2000","2001","2001","2002","2002"),
  basisOfRecord = c(
    "HUMAN_OBSERVATION",
    "PRESERVED_SPECIMEN",
    "HUMAN_OBSERVATION",
    "MATERIAL_SAMPLE",
    "OBSERVATION",
    "FOSSIL_SPECIMEN"
  ),
  count = c(100, 50, 200, 25, 300, 75)
)

# ============================================================
# MOCK FUNCTIONS
# ============================================================

mock_galah_call <- function(...) {
  structure(list(), class = "mock_query")
}

mock_galah_filter <- function(x, ...) x

mock_collect <- function(x, ...) mock_datos_raw

mock_galah_config <- function(...) invisible(NULL)

# ============================================================
# TESTS
# ============================================================

test_that("La función devuelve estructura correcta", {
  
  with_mocked_bindings(
    galah_call   = mock_galah_call,
    galah_filter = mock_galah_filter,
    collect      = mock_collect,
    galah_config = mock_galah_config,
    {
      
      res <- crear_plots_evolucion_basisOfRecord(
        year_ini = 2000,
        year_fin = 2002
      )
      
      expect_type(res, "list")
      expect_named(res, c("lineal", "log", "data"))
      
      expect_s3_class(res$lineal, "ggplot")
      expect_s3_class(res$log, "ggplot")
      expect_s3_class(res$data, "data.frame")
    }
  )
})


test_that("La agregación de datos es correcta", {
  
  with_mocked_bindings(
    galah_call   = mock_galah_call,
    galah_filter = mock_galah_filter,
    collect      = mock_collect,
    galah_config = mock_galah_config,
    {
      
      res <- crear_plots_evolucion_basisOfRecord(
        year_ini = 2000,
        year_fin = 2002
      )
      
      df <- res$data
      
      expect_true(all(
        c("year", "Observaciones", "Especimenes") %in%
          colnames(df)
      ))
      
      expect_equal(df$Observaciones[df$year == 2000], 100)
      expect_equal(df$Especimenes[df$year == 2000], 50)
      
      expect_equal(df$Observaciones[df$year == 2002], 300)
      expect_equal(df$Especimenes[df$year == 2002], 75)
    }
  )
})


test_that("El gráfico lineal incluye eje secundario", {
  
  with_mocked_bindings(
    galah_call   = mock_galah_call,
    galah_filter = mock_galah_filter,
    collect      = mock_collect,
    galah_config = mock_galah_config,
    {
      
      res <- crear_plots_evolucion_basisOfRecord(
        year_ini = 2000,
        year_fin = 2002
      )
      
      y_scale <- res$lineal$scales$get_scales("y")
      
      expect_false(is.null(y_scale$secondary.axis))
    }
  )
})


test_that("El gráfico log usa transformación log10", {
  
  with_mocked_bindings(
    galah_call   = mock_galah_call,
    galah_filter = mock_galah_filter,
    collect      = mock_collect,
    galah_config = mock_galah_config,
    {
      
      res <- crear_plots_evolucion_basisOfRecord(
        year_ini = 2000,
        year_fin = 2002
      )
      
      y_scale <- res$log$scales$get_scales("y")
      
      expect_true(grepl("log", y_scale$trans$name))
      expect_equal(y_scale$trans$name, "log-10")
    }
  )
})
