#' Grafico de barras apiladas sobre el estado de publicacion en GBIF
#'
#' Genera un grafico de barras horizontales apiladas que muestra,
#' por disciplina, el numero de entidades o colecciones que publican
#' y no publican datos en GBIF.
#'
#' Los datos se leen desde archivos `.rds` incluidos en el paquete
#' \pkg{metagesToolkit}, accedidos a traves de la ruta indicada en
#' el argumento \code{rdspath}.
#'
#'
#' @param rdspath Ruta al directorio que contiene los archivos
#'   \code{entidades_per_publican.rds} y
#'   \code{colecciones_per_publican.rds}.
#' @param nivel Caracter. Indica el nivel de agregacion del grafico.
#'   Debe ser uno de:
#'   \itemize{
#'     \item \code{"entidades"}: numero de entidades
#'     \item \code{"colecciones"}: numero de colecciones y bases de datos
#'   }
#'
#' @return Un objeto \code{ggplot} con el grafico de barras apiladas.
#'
#' @details
#' El grafico se ordena de menor a mayor segun el total de entidades
#' o colecciones por disciplina. Se excluye la fila
#' \code{"TOTAL GENERAL"} si esta presente en los datos.
#' Los archivos `.rds` deben contener las columnas
#' \code{disciplina_def}, \code{estado_publicacion} y
#' \code{total_colecciones} o \code{total_entidades}.

#'
#' @seealso
#' \code{\link[ggplot2]{ggplot}},
#' \code{\link[forcats]{fct_reorder}}
#'
#' @examples
#' \dontrun{
#' crear_barplot_publicacion(rdspath = "reports/data/vistas_sql",
#'                           nivel = "entidades")
#' }
#'
#' @export

crear_barplot_publicacion <- function(rdspath,
                                      nivel = c("entidades", "colecciones")) {
  
  nivel <- match.arg(nivel)
  
  if (nivel == "entidades") {
    ruta <- paste0(rdspath, "/entidades_per_publican.rds")
    etiqueta_x <- "N\u00ba entidades"
    total <- "total_entidades"
  } else {
    ruta <- paste0(rdspath, "/colecciones_per_publican.rds")
    etiqueta_x <- "N\u00ba colecciones y bases de datos"
    total <- "total_colecciones"
  }
  
  if (!file.exists(ruta)) {
    stop("No se encuentra el archivo RDS: ", ruta, call. = FALSE)
  }
  
  df <- readRDS(ruta)
  
  df <- dplyr::filter(
    df,
    disciplina_def != "TOTAL GENERAL"
  )
  
  ggplot2::ggplot(
    df,
    ggplot2::aes(
      x = .data[[total]],
      y = forcats::fct_reorder(disciplina_def, .data[[total]], .fun = sum),
      fill = estado_publicacion
    )
  ) +
    ggplot2::geom_col(width = 0.6,
                      alpha = 0.8) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data[[total]]),
      position = ggplot2::position_stack(vjust = 0.5),
      color = "white",
      size = 4.2
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        "Publica en GBIF" = "#3B6AA0",
        "No publica en GBIF" = "#2ECC9A"
      )
    ) +
    ggplot2::labs(
      x = etiqueta_x,
      y = NULL,
      fill = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 13),
    )
}
