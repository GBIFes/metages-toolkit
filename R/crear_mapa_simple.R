#' Mapa METAGES (version simple para uso)
#'
#' Wrapper de alto nivel sobre \code{crear_mapa()} que fija la infraestructura
#' y expone solo filtros y facet.
#'
#' @param tipo_coleccion `colección`, `base de datos` o `NULL`.
#' @param disciplina `Zoológica`, `Botánica`, `Paleontológica`, `Mixta`, `Microbiológica` o `NULL`.
#' @param subdisciplina `Vertebrados`, `Invertebrados`, `Invertebrados y vertebrados`, `Plantas`,  `Hongos y l\u00EDquenes`, `Algas`, `Bot\u00E1nicas mixtas` o `NULL`.
#' @param publican `TRUE`, `FALSE` o `NULL`.
#' @param facet Nombre de columna (string) para facetar o `NULL`.
#'
#' @return Invisiblemente, una lista con:
#' \describe{
#'   \item{plot}{Objeto `ggplot`.}
#'   \item{data_map}{data.frame con los datos tras filtros.}
#' }
#' 
#'   
#' 
#' @export
crear_mapa_simple <- function(tipo_coleccion = NULL,
                         disciplina = NULL,
                         subdisciplina = NULL,
                         publican = NULL,
                         facet = NULL) {
  
  # Infraestructura
  data <- extraer_colecciones_mapa()$data
  basemap <- get_basemap_es()
  legend_params <- compute_legend_params(data)
  
  # Delegación directa al core
  crear_mapa(
    data = data,
    basemap = basemap,
    legend_params = legend_params,
    tipo_coleccion = tipo_coleccion,
    disciplina = disciplina,
    subdisciplina = subdisciplina,
    publican = publican,
    facet = facet
  )
}
