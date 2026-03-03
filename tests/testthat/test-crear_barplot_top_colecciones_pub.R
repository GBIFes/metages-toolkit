test_that("crear_barplot_top_colecciones_pub: caso principal (>=10 publicando)", {
  
  # -----------------------------
  # 1. Crear datos simulados
  # -----------------------------
  df_fake <- data.frame(
    collection_code    = paste0("COL", 1:12),
    coleccion_base     = paste0("Base", 1:12),
    numberOfRecords    = seq(10, 120, by = 10),
    number_of_subunits = seq(5, 60, by = 5),
    publica_en_gbif    = rep(1, 12),
    stringsAsFactors   = FALSE
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_fake, tmp)
  
  # -----------------------------
  # 2. Ejecutar función real
  # -----------------------------
  p <- crear_barplot_top_colecciones_pub(tmp)
  
  # -----------------------------
  # 3. Tests
  # -----------------------------
  expect_s3_class(p, "ggplot")
  
  df_plot <- p$data
  
  # usa numberOfRecords
  expect_true(all(df_plot$value %in% df_fake$numberOfRecords))
  
  # máximo 10 filas
  expect_lte(nrow(df_plot), 10)
  
  # orden descendente
  expect_equal(df_plot$value,
               sort(df_plot$value, decreasing = TRUE))
  
  # label correcto
  expect_equal(p$labels$x, "N\u00BA registros")
})



test_that("crear_barplot_top_colecciones_pub: fallback por subunidades (<10 publicando)", {
  
  df_fake <- data.frame(
    collection_code    = c("COL1", NA, "COL3", "COL4"),
    coleccion_base     = c("Base 1", "Base 2", "Base 3", "Base 4"),
    numberOfRecords    = c(100, 80, 0, 40),
    number_of_subunits = c(10, 20, 30, 40),
    publica_en_gbif    = c(1, 1, 0, 1),
    stringsAsFactors   = FALSE
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_fake, tmp)
  
  p <- crear_barplot_top_colecciones_pub(tmp)
  
  expect_s3_class(p, "ggplot")
  
  df_plot <- p$data
  
  # usa fallback (subunidades)
  expect_true(all(df_plot$value %in% c(10, 20, 30, 40)))
  
  # coalesce funciona
  expect_true("COL1"   %in% df_plot$collection_code)
  expect_true("Base 2" %in% df_plot$collection_code)
  
  # no hay valores 0
  expect_true(all(df_plot$value > 0))
  
  # máximo 10 filas
  expect_lte(nrow(df_plot), 10)
  
  # label fallback correcto
  expect_equal(p$labels$x, "N\u00BA de ejemplares")
})