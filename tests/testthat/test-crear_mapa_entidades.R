library(testthat)

test_that("crear_mapa_entidades: comportamiento general y filtrado por tipo_coleccion", {
  
  with_mocked_bindings(
    
    extraer_colecciones_mapa = function() {
      list(data = test_data)
    },
    
    get_basemap_es = function() {
      test_basemap
    },
    
    {
      
      # ---------------------------
      # 1. Devuelve lista con plot ggplot
      # ---------------------------
      
      res_all <- crear_mapa_entidades()
      
      expect_true(is.list(res_all))
      expect_true("plot" %in% names(res_all))
      expect_s3_class(res_all$plot, "ggplot")
      
      
      # ---------------------------
      # 2. Acepta valores válidos (emite message)
      # ---------------------------
      
      expect_message(crear_mapa_entidades("coleccion"))
      expect_message(crear_mapa_entidades("base de datos"))
      
      
      # ---------------------------
      # 3. Error con valor inválido
      # ---------------------------
      
      expect_error(crear_mapa_entidades("invalido"))
      
      
      # ---------------------------
      # 4. El filtrado por tipo_coleccion funciona
      # ---------------------------
      
      res_col <- crear_mapa_entidades("coleccion")
      res_bd  <- crear_mapa_entidades("base de datos")
      
      p_all <- res_all$plot
      p_col <- res_col$plot
      p_bd  <- res_bd$plot
      
      # geom_point es la 4ª capa
      d_all <- layer_data(p_all, 4)
      d_col <- layer_data(p_col, 4)
      d_bd  <- layer_data(p_bd, 4)
      
      expect_gt(nrow(d_all), nrow(d_col))
      expect_gt(nrow(d_all), nrow(d_bd))
      
      
      # ---------------------------
      # 5. El título cambia correctamente
      # ---------------------------
      
      expect_match(
        p_all$labels$title,
        "colecciones biológicas y bases de datos"
      )
      
      expect_match(
        p_col$labels$title,
        "colecciones biológicas"
      )
      
      expect_match(
        p_bd$labels$title,
        "bases de datos"
      )
    }
  )
})