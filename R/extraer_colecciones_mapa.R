#' Extraer colecciones desde METAGES para mapas
#'
#' Abre conexión a METAGES (vía \code{conectar_metages()}), ejecuta una consulta
#' (`SELECT * FROM colecciones c`) y devuelve un data.frame depurado para mapas.
#'
#' @param shift Vector numérico de longitud 2. Se usa en el procesamiento para 
#'    desplazar los datos de canarias y coincidir con \code{get_basemap_es()}.
#' @param cerrar_conexion Si `TRUE`, cierra la conexión DB al finalizar.
#' @param cerrar_tunel Si `TRUE`, cierra el túnel/proceso al finalizar.
#'
#' @return Invisiblemente, un data.frame/tibble con los datos de colecciones
#'   listos para usar en \code{crear_mapa()}.
#'
#' @import dplyr
#'
#' @export

extraer_colecciones_mapa <- function(shift = c(5, 6),
                                 cerrar_conexion = FALSE,
                                 cerrar_tunel = FALSE) {
  
  # 1. Abrir conexión + túnel
  cm <- conectar_metages()
  
  con <- cm$con
  tunnel <- cm$tunnel
  
  # 2. Extraer datos de metages
  colecciones <- dbGetQuery(con,
                            "SELECT * FROM colecciones c"
                  )
  
  # 3. Limpiar tabla y anhadir geometria 
  data <- colecciones %>% mutate(across(where(is.character),
                                        ~ na_if(trimws(.), 
                                                ""))) %>%
                          filter(!is.na(town)) %>%
                          mutate(
                            town = factor(town, unique(town)),
                            latitude = as.numeric(latitude),
                            longitude = as.numeric(longitude),
                            # el desplazamiento de longitude_adj y latitude_adj debe coincidir con 
                            # el de ES_canary_shifted de get_basemap_es.R
                            longitude_adj = if_else(
                                                longitude < -10 & latitude < 34,
                                                longitude + shift[1],
                                                longitude
                                              ),
                            latitude_adj = if_else(
                                                longitude < -10 & latitude < 34,
                                                latitude + shift[2],
                                                latitude
                                              )
                          )
  
  # 4. Cierres opcionales
  if (isTRUE(cerrar_conexion)) {
    dbDisconnect(con)
  }
  
  if (isTRUE(cerrar_tunel) && 
      !is.null(tunnel) &&
      tunnel$is_alive()) {
    tunnel$kill()
  }
  
  # 5. Devolver lo útil
  return(invisible(list(
    data = data,
    con = con,
    tunnel = tunnel
  )))
}
