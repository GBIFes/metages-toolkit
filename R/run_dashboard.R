#' Lanzar el Dashboard interactivo de METAGES
#'
#' Abre un dashboard Shiny con las métricas, tablas e imágenes generadas por
#' \pkg{metagesToolkit}, permitiendo explorar y filtrar los datos del Registro
#' de Colecciones de GBIF España de forma interactiva.
#'
#' El dashboard incluye cuatro secciones:
#' \describe{
#'   \item{Resumen}{Métricas globales (número de colecciones, entidades,
#'     publicadores y registros en GBIF) y gráficas de distribución.}
#'   \item{Mapa}{Mapa interactivo de colecciones y bases de datos, con filtros
#'     por tipo de recurso, disciplina, subdisciplina y estado de publicación
#'     en GBIF.}
#'   \item{Gráficos}{Gráficas con evolución temporal, distribución por
#'     disciplina (pie chart), publicación en GBIF y colecciones con más
#'     registros.}
#'   \item{Tablas}{Tabla descargable con todos los registros, filtrable por
#'     tipo, disciplina, subdisciplina y publicación en GBIF.}
#' }
#'
#' @param ... Argumentos adicionales pasados a \code{\link[shiny]{runApp}}
#'   (por ejemplo, \code{port}, \code{host} o \code{launch.browser}).
#'
#' @return Se llama por sus efectos secundarios (lanzar la aplicación Shiny).
#'   Devuelve invisiblemente la ruta al directorio de la aplicación.
#'
#' @examples
#' \dontrun{
#' # Lanzar con el navegador por defecto
#' run_dashboard()
#'
#' # Lanzar en un puerto específico sin abrir el navegador
#' run_dashboard(port = 4321, launch.browser = FALSE)
#' }
#'
#' @export
run_dashboard <- function(...) {

  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop(
      "El paquete 'shiny' es necesario para ejecutar el dashboard. ",
      "Inst\u00e1lalo con: install.packages('shiny')",
      call. = FALSE
    )
  }

  if (!requireNamespace("DT", quietly = TRUE)) {
    stop(
      "El paquete 'DT' es necesario para ejecutar el dashboard. ",
      "Inst\u00e1lalo con: install.packages('DT')",
      call. = FALSE
    )
  }

  app_dir <- system.file("shiny", "metages_dashboard",
                         package = "metagesToolkit")

  if (!nzchar(app_dir)) {
    stop(
      "No se ha encontrado el directorio de la aplicaci\u00f3n Shiny en el paquete.",
      call. = FALSE
    )
  }

  invisible(shiny::runApp(app_dir, ...))
}
