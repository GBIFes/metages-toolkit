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
library(fs)
library(here)


# -------------------------------------------------------------------
# 0.0 Flags de seguridad
# -------------------------------------------------------------------
LIMPIAR_DESTINOS <- TRUE

# Recomendado: bloquear borrado si no es interactivo (CI, Rscript, etc.)
# Si alguna vez quieres permitirlo en CI, cambia la condición o usa un ENV VAR.
if (LIMPIAR_DESTINOS && !interactive()) {
  stop(
    "Este script borra artefactos (LIMPIAR_DESTINOS=TRUE) y requiere ejecución interactiva.\n",
    "Pon LIMPIAR_DESTINOS <- FALSE o ajusta la condición si lo necesitas en CI."
  )
}


# ------------------------------------------------------------
# 0.1 Definicion de rutas y creacion de carpetas
# ------------------------------------------------------------
pkg_root <- here::here()

# Necesarias en vignettes/ para pkgdown::build_site() 
# ↳ No `git push` para evitar ruido en repo publico
# ↳ Si quieremos contruir el site con Github Actions tendrian que pushearse (pero duplica las imagenes)
dir_fig_maps_vign  <- fs::path(pkg_root, "vignettes", "figures") 

# Necesarias en inst/ para que informe.qmd las encuentre desde render_informe()
dir_fig_maps_inst  <- fs::path(pkg_root, "inst", "reports", "assets", "images", "generated")

dir_data_root <- fs::path(pkg_root, "inst", "reports", "data")
dir_data_maps <- fs::path(dir_data_root, "mapas")
dir_data_sql  <- fs::path(dir_data_root, "vistas_sql")

# Crea TODAS las carpetas necesarias
fs::dir_create(c(dir_fig_maps_inst, dir_fig_maps_vign, dir_data_maps, dir_data_sql), recurse = TRUE)



# ------------------------------------------------------------
# 0.2 Limpieza de carpetas de destino
# ------------------------------------------------------------

limpiar_dir <- function(dir) {
  if (!fs::dir_exists(dir)) return(invisible(NULL))
  files <- fs::dir_ls(dir, recurse = TRUE, type = "file")
  if (length(files) > 0) fs::file_delete(files)
  invisible(NULL)
}

if (LIMPIAR_DESTINOS) {
  limpiar_dir(dir_fig_maps_vign)
  limpiar_dir(dir_fig_maps_inst)
  limpiar_dir(dir_data_maps)
  limpiar_dir(dir_data_sql)
}

message("==> Rutas de destino definidas y limpias.")



message("==> Iniciando actualización de mapas para vignettes")

# ------------------------------------------------------------
# 1.1 Extraer y guardar datos de MetaGES (privado)
# ------------------------------------------------------------
message(" - Extrayendo datos del Registro...")

con <- conectar_metages()$con # Solo necesario para vistas SQL

message(" - Descargando vistas SQL")

vistas_sql <- list(
  colecciones                 = "SELECT * FROM colecciones",
  colecciones_informatizacion = "SELECT * FROM colecciones_informatizacion_ejemplares",
  colecciones_informatizacion_ejemplares_bot = "SELECT * FROM colecciones_informatizacion_ejemplares_bot",
  colecciones_informatizacion_ejemplares_zoo = "SELECT * FROM colecciones_informatizacion_ejemplares_zoo",
  colecciones_informatizacion_ejemplares_micro = "SELECT * FROM colecciones_informatizacion_ejemplares_micro",
  colecciones_informatizacion_ejemplares_mixta = "SELECT * FROM colecciones_informatizacion_ejemplares_mixta",
  colecciones_informatizacion_ejemplares_paleo = "SELECT * FROM colecciones_informatizacion_ejemplares_paleo",
  colecciones_per_anno        = "SELECT * FROM colecciones_per_anno",
  colecciones_per_publican    = "SELECT * FROM colecciones_per_estado_publicacion",
  colecciones_por_disciplina  = "SELECT * FROM colecciones_por_disciplina",
  colecciones_por_subdisciplina_botanica  = "SELECT * FROM colecciones_por_subdisciplina_botanica",
  colecciones_por_subdisciplina_zoologica  = "SELECT * FROM colecciones_por_subdisciplina_zoologica",
  colecciones_uso_software_bot  = "SELECT * FROM colecciones_uso_software_bot",
  colecciones_uso_software_zoo  = "SELECT * FROM colecciones_uso_software_zoo",
  colecciones_uso_software_micro  = "SELECT * FROM colecciones_uso_software_micro",
  colecciones_uso_software_mixta  = "SELECT * FROM colecciones_uso_software_mixta",
  colecciones_uso_software_paleo  = "SELECT * FROM colecciones_uso_software_paleo",
  registros_por_disciplina    = "SELECT * FROM registros_por_disciplina",
  registros_por_disciplina_col    = "SELECT * FROM registros_por_disciplina_col",
  registros_por_disciplina_bd    = "SELECT * FROM registros_por_disciplina_bd"
)

for (nombre in names(vistas_sql)) {
  message("   ↳ ", nombre)
  
  df <- DBI::dbGetQuery(con, vistas_sql[[nombre]])
  
  saveRDS(
    df,
    file = fs::path(dir_data_sql, paste0(nombre, ".rds"))
  )
}

# ------------------------------------------------------------
# 1.2 Crear y guardar datos derivados de las vistas SQL
# ------------------------------------------------------------

message(" - Generando tablas derivadas de vistas SQL")

df <- readRDS("inst/reports/data/vistas_sql/colecciones.rds")


# Proporcion de tipos de colecciones segun el tipo de evidencia tras los registros
df %>%
  mutate(
    tipo_body = recode(
      tipo_body,
      "coleccion" = "Colecciones biológicas",
      "base_datos" = "Bases de datos"
    )
  ) %>%
  count(`2º nivel: colección / base de datos` = tipo_body) %>%
  mutate(
    Porcentaje = n / sum(n) * 100
  ) %>%
  mutate(
    Porcentaje = sprintf("%.2f %%", Porcentaje)
  )  %>%
  bind_rows(
    tibble(
      `2º nivel: colección / base de datos` = "TOTAL",
      n = sum(.$n),
      Porcentaje = "100 %"
    )
  ) %>%
  rename(`Nº colecciones` = n) %>%
  saveRDS(file = fs::path(dir_data_sql, "proporcion_col_base.rds"))




# Estado de conservación de las colecciones
df %>% filter(tipo_body == "coleccion") %>%
        mutate(condiciones_col = if_else(is.na(condiciones_col),
                                          "No especificado",
                                          condiciones_col)) %>%
        count(condiciones_col, name = "Número de colecciones") %>%
        mutate(`%` = paste0(round(
                              100 * `Número de colecciones` / sum(`Número de colecciones`), 
                              2),
                            " %")) %>%
        rename(`Condiciones de conservación` = condiciones_col) %>%
        mutate(`Condiciones de conservación` = factor(
                                                  `Condiciones de conservación`,
                                                  levels = c(
                                                    "Óptimas",
                                                    "Óptimas - adecuadas",
                                                    "Adecuadas",
                                                    "Malas - adecuadas",
                                                    "Malas",
                                                    "No especificado"
                                                  ))) %>%
        arrange(`Condiciones de conservación`) %>%
        saveRDS(file = fs::path(dir_data_sql, "estado_conservacion.rds"))


# Accesibilidad a los ejemplares
df %>% filter(tipo_body == "coleccion") %>%
        mutate(acceso_ejemplares = case_when(is.na(acceso_ejemplares) ~ "No disponible o no especificado",
                                             acceso_ejemplares == "No disponible" ~ "No disponible o no especificado",
                                             acceso_ejemplares == "Libre acceso" ~ "Al público en general",
                                             TRUE ~ acceso_ejemplares)) %>%
        count(acceso_ejemplares, name = "Número de colecciones") %>%
        mutate(`%` = paste0(round(
                              100 * `Número de colecciones` / sum(`Número de colecciones`),
                              2),
                            " %")) %>%
        rename(`Accesibilidad a los ejemplares` = acceso_ejemplares) %>%
        mutate(`Accesibilidad a los ejemplares` = factor(
                                              `Accesibilidad a los ejemplares`,
                                              levels = c(
                                                "Al público en general",
                                                "A investigadores o personal in situ",
                                                "Se hacen préstamos",
                                                "No disponible o no especificado"))) %>%
        arrange(`Accesibilidad a los ejemplares`) %>%
        saveRDS(file = fs::path(dir_data_sql, "acceso_ejemplares.rds"))


# Accesibilidad a los datos informatizados de los ejemplares
df %>% filter(tipo_body == "coleccion") %>%
  mutate(acceso_informatizado = if_else(is.na(acceso_informatizado),
                                   "No especificado",
                                   acceso_informatizado)) %>%
  count(acceso_informatizado, name = "Número de colecciones") %>%
  mutate(`%` = paste0(round(
    100 * `Número de colecciones` / sum(`Número de colecciones`), 
    2),
    " %")) %>%
  rename(`Accesibilidad a los datos informatizados` = acceso_informatizado) %>%
  mutate(`Accesibilidad a los datos informatizados` = factor(
    `Accesibilidad a los datos informatizados`,
    levels = c(
      "Libre acceso",
      "Caso por caso",
      "Protegido por clave",
      "Otros",
      "No disponible",
      "No especificado"
    ))) %>%
  arrange(`Accesibilidad a los datos informatizados`) %>%
  saveRDS(file = fs::path(dir_data_sql, "acceso_informatizado.rds"))



# Medio de acceso a los datos informatizados de los ejemplares
# df %>% filter(tipo_body == "coleccion") %>%
#   mutate(acceso_informatizado = if_else(is.na(acceso_informatizado),
#                                         "No especificado",
#                                         acceso_informatizado)) %>%
#   count(acceso_informatizado, name = "Número de colecciones") %>%
#   mutate(`%` = paste0(round(
#     100 * `Número de colecciones` / sum(`Número de colecciones`), 
#     2),
#     " %")) %>%
#   rename(`Accesibilidad a los datos informatizados` = acceso_informatizado) %>%
#   mutate(`Accesibilidad a los datos informatizados` = factor(
#     `Accesibilidad a los datos informatizados`,
#     levels = c(
#       "Libre acceso",
#       "Caso por caso",
#       "Protegido por clave",
#       "Otros",
#       "No disponible",
#       "No especificado"
#     ))) %>%
#   arrange(`Accesibilidad a los datos informatizados`) %>%
#   saveRDS(file = fs::path(dir_data_sql, "acceso_informatizado.rds"))








# ------------------------------------------------------------
# 2. Preparar carpeta de salida para mapas
# ------------------------------------------------------------

# Parámetros comunes de exportación
gg_opts_all <- list(
  width  = 9,
  height = 6,
  dpi    = 100
)

# Función auxiliar para guardar mapas
save_map <- function(plot, filename, gg_opts = gg_opts_all) {
  message("   * Guardando ", filename)
  
  for (dir in c(dir_fig_maps_inst, dir_fig_maps_vign)) {
    do.call(
      ggplot2::ggsave,
      c(
        list(
          filename = file.path(dir, filename),
          plot     = plot
        ),
        gg_opts
      )
    )
  }
}


# Función auxiliar para guardar barplots
save_plot <- function(plot, filename, width = 10) {
  message("   * Guardando barplot ", filename)
  
  for (dir in c(dir_fig_maps_inst, dir_fig_maps_vign)) {
    ggplot2::ggsave(
      filename  = file.path(dir, filename),
      plot      = plot,
      width     = width,
      height    = 6,
      units     = "in",
      dpi       = 300,
      limitsize = FALSE
    )
  }
}



# ------------------------------------------------------------
# 3.0 Mapa entidades
# ------------------------------------------------------------
message(" - Generando mapa total")
mapa_entidades <- crear_mapa_entidades()

save_map(
  plot     = mapa_entidades,
  filename = "mapa-entidades.png"
)


# ------------------------------------------------------------
# 3.1 Mapa total
# ------------------------------------------------------------
message(" - Generando mapa total")
res_total <- crear_mapa_simple()

save_map(
  plot     = res_total$plot,
  filename = "mapa-total.png"
)

# Extraer datos de extraer_colecciones_mapa en lugar de desde crear_mapa_simple
# porque crear_mapa_simple tiene filtros propios relacionados con la `variable activa`
# y no muestra todos los registros. Con extraer_colecciones_mapa se muestran todos.
saveRDS(
  extraer_colecciones_mapa()$data,
  file = fs::path(dir_data_maps, "mapa-total.rds")
)


# ------------------------------------------------------------
# 3.2 Mapa colecciones segun publicacion en GBIF
# ------------------------------------------------------------
message(" - Generando mapa total")
mapa_col_pub <- crear_mapa_entidades(
  tipo_coleccion = "coleccion")

save_map(
  plot     = mapa_col_pub,
  filename = "mapa_col_pub.png"
)

saveRDS(
  mapa_col_pub$data_map,
  file = fs::path(dir_data_maps, "mapa_col_pub.rds")
)


##############################################################

# ------------------------------------------------------------
# 4. Mapa colecciones zoológicas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-zoo.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-zoo.rds")),
          filename = "barplot-colecciones-zoo.png",
          width = 12)


# ------------------------------------------------------------
# 5. Mapa colecciones zoológicas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-zoo-pub.rds")
)

# ------------------------------------------------------------
# 6. Mapa colecciones de invertebrados
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-inv.rds")
)


save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-inv.rds")),
          filename = "barplot-colecciones-inv.png",
          width = 12)

# ------------------------------------------------------------
# 7. Mapa colecciones de invertebrados (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-inv-pub.rds")
)


# ------------------------------------------------------------
# 8. Mapa colecciones de Vertebrados
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de Vertebrados")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Vertebrados"
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-vert.png"
)

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-vert.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-vert.rds")),
          filename = "barplot-colecciones-vert.png",
          width = 12)

# ------------------------------------------------------------
# 9. Mapa colecciones Vertebrados (publicadoras)
# ------------------------------------------------------------
message(" - Generando mapa de colecciones Vertebrados publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Vertebrados",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-vert-pub.png"
)

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-vert-pub.rds")
)

# ------------------------------------------------------------
# 10. Mapa colecciones de invertebrados y vertebrados
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-invver.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-invver.rds")),
          filename = "barplot-colecciones-invver.png",
          width = 12)

# ------------------------------------------------------------
# 11. Mapa colecciones de invertebrados y vertebrados publicadoras
# ------------------------------------------------------------
message(" - Generando mapa de colecciones de invertebrados y vertebrados publicadoras")
res_colecciones <- crear_mapa_simple(
  tipo_coleccion = "coleccion",
  subdisciplina = "Invertebrados y vertebrados",
  publican = T
)

save_map(
  plot     = res_colecciones$plot,
  filename = "mapa-colecciones-invver-pub.png"
)

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-invver-pub.rds")
)


# ------------------------------------------------------------
# 12. Mapa colecciones botanicas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-bot.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-bot.rds")),
          filename = "barplot-colecciones-bot.png",
          width = 12)

# ------------------------------------------------------------
# 13. Mapa colecciones botanicas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-bot-pub.rds")
)


# ------------------------------------------------------------
# 14. Mapa colecciones de plantas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-pla.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-pla.rds")),
          filename = "barplot-colecciones-pla.png",
          width = 12)


# ------------------------------------------------------------
# 15. Mapa colecciones de plantas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-pla-pub.rds")
)


# ------------------------------------------------------------
# 16. Mapa colecciones de Algas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-alg.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-alg.rds")),
          filename = "barplot-colecciones-alg.png",
          width = 12)


# ------------------------------------------------------------
# 17. Mapa colecciones Algas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-alg-pub.rds")
)


# ------------------------------------------------------------
# 18. Mapa colecciones de hongos
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-hong.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-hong.rds")),
          filename = "barplot-colecciones-hong.png",
          width = 12)


# ------------------------------------------------------------
# 19. Mapa colecciones de hongos publicadoras
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-hong-pub.rds")
)


# ------------------------------------------------------------
# 20. Mapa colecciones microbiologicas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-micro.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-micro.rds")),
          filename = "barplot-colecciones-micro.png",
          width = 12)


# ------------------------------------------------------------
# 21. Mapa colecciones microbiologicas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-micro-pub.rds")
)


# ------------------------------------------------------------
# 22. Mapa colecciones micologicas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-mico.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-mico.rds")),
          filename = "barplot-colecciones-mico.png",
          width = 12)


# ------------------------------------------------------------
# 23. Mapa colecciones micologicas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-mico.rds")
)

# ------------------------------------------------------------
# 24. Mapa colecciones Paleontologicas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-pale.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-pale.rds")),
          filename = "barplot-colecciones-pale.png",
          width = 12)


# ------------------------------------------------------------
# 25. Mapa colecciones Paleontologicas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-pale-pub.rds")
)


# ------------------------------------------------------------
# 26. Mapa colecciones Mixtas
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-mix.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-colecciones-mix.rds")),
          filename = "barplot-colecciones-mix.png",
          width = 12)


# ------------------------------------------------------------
# 27. Mapa colecciones Mixtas (publicadoras)
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

saveRDS(
  res_colecciones$data_map,
  file = fs::path(dir_data_maps, "mapa-colecciones-mix-pub.rds")
)



# ------------------------------------------------------------
# 28. Mapa facetado por bases de datos 
# ------------------------------------------------------------
message(" - Generando mapa bd facetado por disciplina")
res_facet <- crear_mapa_simple(
  tipo_coleccion = "base de datos",
  facet = "disciplina_def"
)

save_map(
  plot     = res_facet$plot,
  filename = "mapa-facet-bd-disciplina.png",
  gg_opts = list(width  = 14,
                 height = 9,
                 dpi    = 100)
)

saveRDS(
  res_facet$data_map,
  file = fs::path(dir_data_maps, "mapa-facet-bd-disciplina.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-facet-bd-disciplina.rds")),
          filename = "barplot-facet-bd-disciplina.png",
          width = 12)


# ------------------------------------------------------------
# 29. Mapa facetado por bases de datos publicadoras
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

saveRDS(
  res_facet$data_map,
  file = fs::path(dir_data_maps, "mapa-facet-bd-disciplina-pub.rds")
)

save_plot(plot = crear_barplot_top_colecciones_pub(paste0(dir_data_maps, 
                                                          "/mapa-facet-bd-disciplina-pub.rds")),
          filename = "barplot-facet-bd-disciplina-pub.png",
          width = 12)



# ------------------------------------------------------------
# 30. Mapa facetado por bases de datos no publicadoras
# ------------------------------------------------------------
message(" - Generando mapa bd facetado por disciplina no publicadoras")

tryCatch(
  {
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
    
    saveRDS(
      res_colecciones$data_map,
      file = fs::path(dir_data_maps, "mapa-facet-bd-disciplina-nopub.rds")
    )
  },
  error = function(e) {
    message(" ↳ Sin datos para generar este mapa (se omite).")
    invisible(NULL)
  }
)


# ------------------------------------------------------------
# 31. Fin
# ------------------------------------------------------------
message("==> Mapas de vignettes actualizados correctamente")
