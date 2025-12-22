#' Obtener basemap de España (con Canarias desplazadas)
#'
#' Descarga geometrías de países vecinos y España con `giscoR`, recorta
#' y desplaza Canarias para crear un basemap “compacto” para mapas.
#'
#' @param shift Vector numérico de longitud 2 con el desplazamiento aplicado
#'   a Canarias (x, y).
#'
#' @return Invisiblemente, una lista con:
#' \describe{
#'   \item{vecinos}{Objeto sf con países vecinos.}
#'   \item{ES_fixed}{Objeto sf con España (Península+Canarias desplazadas).}
#'   \item{bb_fixed}{Bounding box (`sf::st_bbox`) de `ES_fixed`.}
#'   \item{bb_can}{Bounding box (`sf::st_bbox`) de Canarias desplazadas.}
#'   \item{shift}{El vector `shift` usado para desplazar canarias.}
#' }
#'
#' @import giscoR
#'
#' @export

get_basemap_es <- function(shift = c(5, 6)) {

  # Descarga basemap
  vecinos <- gisco_get_countries(
                      country = c("PT", "FR", "AD", "MA", "DZ"),
                      resolution = 1
              )
  
  ES <- gisco_get_countries(country = "ES", resolution = 1)
  
  ES_main <- st_crop(ES, xmin = -10, xmax = 5, ymin = 35, ymax = 44)      # Península y Baleares
  ES_canary  <- st_crop(ES, xmin = -19, xmax = -10, ymin = 27, ymax = 33) # Canarias

  # Desplazar Canarias hacia el noreste
  ES_canary_shifted <- ES_canary |>
    mutate(geometry = geometry + shift) |> # (desplaza X, desplaza Y)
    st_set_crs(st_crs(ES))
  
  # Crear basemap final y definir bounding boxes
  ES_fixed <- rbind(ES_main, ES_canary_shifted)
  
  # Guardar geometrias
  return(invisible(list(
    vecinos = vecinos,
    ES_fixed = ES_fixed,
    bb_fixed = st_bbox(ES_fixed),
    bb_can   = st_bbox(ES_canary_shifted),
    shift = shift
  )))
}
