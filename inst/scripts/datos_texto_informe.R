# SQL Views
con <- conectar_metages(
  driver = params$odbc_driver
)$con

dom <- extraer_colecciones_mapa(odbc_driver = params$odbc_driver)
data <- dom$data


#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

# Lectura interna
colbd <- readRDS("inst/reports/data/mapas/mapa-total.rds")
reg <- readRDS("inst/reports/data/vistas_sql/registros.rds")



# data
# entidades
n_entidades_actual <- colbd %>% select (institucion_proyecto) %>% distinct() %>% nrow()
n_entidades_actual_pub <- colbd %>% filter(publica_en_gbif == 1) %>% select(institucion_proyecto) %>% distinct() %>% nrow()
n_entidades_actual_pub_x100 <- paste0((n_entidades_actual_pub * 100 / n_entidades_actual) %>% round(1), "%")
n_entidades_informe_anterior <- 229 # Manual
n_entidades_incremento <- n_entidades_actual - n_entidades_informe_anterior
n_entidades_incremento_x100 <- paste0((n_entidades_incremento * 100 / n_entidades_informe_anterior) %>% round(1), "%")


# colbd
n_colbd_actual <- nrow(colbd)
n_colbd_informe_anterior <- 474 # Manual
n_colbd_incremento <- n_colbd_actual - n_colbd_informe_anterior
n_colbd_incremento_x100 <- paste0((n_colbd_incremento * 100 / n_colbd_informe_anterior) %>% round(1), "%")

# recursos
n_recursos_actual <- nrow(reg)
n_recursos_informe_anterior <- 308 # Manual
n_recursos_incremento <- n_recursos_actual - n_recursos_informe_anterior
n_recursos_incremento_x100 <- paste0((n_recursos_incremento * 100 / n_recursos_informe_anterior) %>% round(1), "%")

# registros
n_registros_actual <- sum(as.integer(reg$numberOfRecords)) %>% format(decimal.mark = ",", big.mark = ".")
n_registros_informe_anterior <- 32367320 # Manual
n_registros_incremento <- (sum(as.integer(reg$numberOfRecords)) - n_registros_informe_anterior) %>% format(decimal.mark = ",", big.mark = ".")
n_registros_incremento_x100 <- paste0(((sum(as.integer(reg$numberOfRecords)) - n_registros_informe_anterior) * 100 / n_registros_informe_anterior) %>% round(1), "%")




n_edicion_informe_anterior <- "sexta" # Manual
n_edicion_informe_actual <- "septima" # Manual
anno_actual <- format(Sys.Date(), "%Y")
anno_informe_anterior <- 2019 # Manual
mes_anno_informe_anterior <- "diciembre de 2019" # Manual
mes_anno_actual <- format(Sys.Date(), "%B de %Y")