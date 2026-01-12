# ============================================================
# Script: actualizar_mapas_vignettes.R
# Actualiza las imágenes de mapas usadas en vignettes pkgdown
#
# NOTA:
# - El script en sí NO requiere credenciales.
# - Las credenciales solo son necesarias porque se llama a
#   extraer_colecciones_mapa().
# - Las imágenes se SOBREESCRIBEN en cada ejecución.
# ============================================================

library(metagesToolkit)
library(ggplot2)
library(dplyr)

message("==> Iniciando actualización de mapas para vignettes")

# ------------------------------------------------------------
# 1. Extraer datos (privado)
# ------------------------------------------------------------
message(" - Extrayendo datos del Registro...")
dom  <- extraer_colecciones_mapa()
data <- dom$data

# ------------------------------------------------------------
# 2. Preparar carpeta de salida
# ------------------------------------------------------------
fig_dir <- file.path("vignettes", "figures")
if (!dir.exists(fig_dir)) {
  dir.create(fig_dir, recursive = TRUE)
  message(" - Carpeta creada: ", fig_dir)
}

# Parámetros comunes de exportación
gg_opts_all <- list(
  width  = 9,
  height = 6,
  dpi    = 100
)

# Función auxiliar para guardar mapas
save_map <- function(plot, filename, gg_opts = gg_opts_all) {
  message("   * Guardando ", filename)
  do.call(
    ggplot2::ggsave,
    c(
      list(
        filename = file.path(fig_dir, filename),
        plot     = plot
      ),
      gg_opts
    )
  )
}

# ------------------------------------------------------------
# 3. Mapa total
# ------------------------------------------------------------
message(" - Generando mapa total")
res_total <- crear_mapa_simple()

save_map(
  plot     = res_total$plot,
  filename = "mapa-total.png"
)


##############################################################

# ------------------------------------------------------------
# 4. Mapa solo colecciones zoológicas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones zoológicas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Zoo"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-zoo.png"
)


# ------------------------------------------------------------
# 5. Mapa solo colecciones zoológicas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones zoológicas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Zoo",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-zoo-pub.png"
)


# ------------------------------------------------------------
# 6. Mapa solo colecciones de invertebrados
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de invertebrados")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Invertebrados"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-inv.png"
)


# ------------------------------------------------------------
# 7. Mapa solo colecciones de invertebrados (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de invertebrados publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Invertebrados",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-inv-pub.png"
)


# ------------------------------------------------------------
# 8. Mapa solo colecciones de Vertebrados
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de Vertebrados")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Vertebrados"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-zoo-vert.png"
)


# ------------------------------------------------------------
# 9. Mapa solo colecciones Vertebrados (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones Vertebrados publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Vertebrados",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-zoo-vert-pub.png"
)


# ------------------------------------------------------------
# 10. Mapa solo colecciones de invertebrados y vertebrados
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de invertebrados y vertebrados")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Invertebrados y vertebrados"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-invver.png"
)

# ------------------------------------------------------------
# 11. Mapa solo colecciones de invertebrados y vertebrados publicadoras
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de invertebrados y vertebrados publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Invertebrados y vertebrados",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-invver_pub.png"
)


# ------------------------------------------------------------
# 12. Mapa solo colecciones botanicas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones botanicas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Bot"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-bot.png"
)


# ------------------------------------------------------------
# 13. Mapa solo colecciones botanicas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones botanicas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Bot",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-bot-pub.png"
)


# ------------------------------------------------------------
# 14. Mapa solo colecciones de plantas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de plantas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Plant"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-pla.png"
)


# ------------------------------------------------------------
# 15. Mapa solo colecciones de plantas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de plantas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Plant",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-pla-pub.png"
)


# ------------------------------------------------------------
# 16. Mapa solo colecciones de Algas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de Algas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Algas"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-alg.png"
)


# ------------------------------------------------------------
# 17. Mapa solo colecciones Algas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de Algas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Algas",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-alg-pub.png"
)


# ------------------------------------------------------------
# 18. Mapa solo colecciones de hongos
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de hongos")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Hong"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-hong.png"
)

# ------------------------------------------------------------
# 19. Mapa solo colecciones de hongos publicadoras
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de hongos publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Hong",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-hong-pub.png"
)


# ------------------------------------------------------------
# 20. Mapa solo colecciones microbiologicas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones microbiologicas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Micro"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-micro.png"
)


# ------------------------------------------------------------
# 21. Mapa solo colecciones microbiologicas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones microbiologicas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Micro",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-micro-pub.png"
)


# ------------------------------------------------------------
# 22. Mapa solo colecciones micologicas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones micologicas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Mico"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-mico.png"
)


# ------------------------------------------------------------
# 23. Mapa solo colecciones micologicas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones micologicas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Mico",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-mico.png"
)

# ------------------------------------------------------------
# 24. Mapa solo colecciones Paleontologicas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones Paleontologicas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Pale"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-pale.png"
)


# ------------------------------------------------------------
# 25. Mapa solo colecciones Paleontologicas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones Paleontologicas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Pale",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-pale-pub.png"
)


# ------------------------------------------------------------
# 26. Mapa solo colecciones Mixtas
# ------------------------------------------------------------
message(" - Generando mapa de colecciones Mixtas")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Mix"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-mix.png"
)


# ------------------------------------------------------------
# 27. Mapa solo colecciones Mixtas (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones Mixtas publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  disciplina = "Mix",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-mix-pub.png"
)



# ------------------------------------------------------------
# 28. Mapa facetado por bases de datos publicadoras
# ------------------------------------------------------------
message(" - Generando mapa bd facetado por disciplina publicadoras")
res_facet <- crear_mapa_simple(
  tipo_coleccion = "base de datos",
  facet = "disciplina_def",
  publican = T
)

save_map(
  plot     = res_facet$plot,
  filename = "mapa-facet-bd-disciplina-pub.png",
  gg_opts = list(width  = 14,
                 height = 9,
                 dpi    = 100)
)



# ------------------------------------------------------------
# 29. Mapa facetado por bases de datos no publicadoras
# ------------------------------------------------------------
message(" - Generando mapa bd facetado por disciplina no publicadoras")
res_facet <- crear_mapa_simple(
  tipo_coleccion = "base de datos",
  facet = "disciplina_def",
  publican = F
)

save_map(
  plot     = res_facet$plot,
  filename = "mapa-facet-bd-disciplina-nopub.png",
  gg_opts = list(width  = 14,
                 height = 9,
                 dpi    = 100)
)

# ------------------------------------------------------------
# 7. Fin
# ------------------------------------------------------------
message("==> Mapas de vignettes actualizados correctamente")
