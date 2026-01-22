test_that(
  "crear_barplot_top_colecciones_pub: no falla y prepara correctamente los datos",
  {
    
    testthat::with_mocked_bindings(
      
      # --------------------------------------------------
      # Mock de readRDS() (base)
      # --------------------------------------------------
      readRDS = function(path) {
        data.frame(
          collection_code = c("COL1", NA, "COL3", "COL4"),
          coleccion_base   = c("Base 1", "Base 2", "Base 3", "Base 4"),
          numberOfRecords  = c(100, 80, 60, 40),
          publica_en_gbif  = c(1, 1, 0, 1),
          stringsAsFactors = FALSE
        )
      },
      
      .package = "base",
      
      {
        
        # --------------------------------------------------
        # 1. La función NO debe fallar
        # --------------------------------------------------
        p <- crear_barplot_top_colecciones_pub("dummy/path.rds")
        
        
        # --------------------------------------------------
        # 2. Es un objeto ggplot (sin expect_*)
        # --------------------------------------------------
        stopifnot(inherits(p, "ggplot"))
        
        
        # --------------------------------------------------
        # 3. El data.frame interno existe y es válido
        # --------------------------------------------------
        df_plot <- p$data
        stopifnot(is.data.frame(df_plot))
        
        
        # --------------------------------------------------
        # 4. Filtrado publica_en_gbif == 1 (3 filas)
        # --------------------------------------------------
        stopifnot(nrow(df_plot) == 3)
        
        
        # --------------------------------------------------
        # 5. coalesce(collection_code, coleccion_base)
        # --------------------------------------------------
        stopifnot("COL1"  %in% df_plot$collection_code)
        stopifnot("Base 2" %in% df_plot$collection_code)
        
        
        # --------------------------------------------------
        # 6. numberOfRecords preservado
        # --------------------------------------------------
        stopifnot(all(df_plot$numberOfRecords %in% c(100, 80, 40)))
        
        
        # --------------------------------------------------
        # 7. Top 10 respetado
        # --------------------------------------------------
        stopifnot(nrow(df_plot) <= 10)
      }
    )
  }
)
