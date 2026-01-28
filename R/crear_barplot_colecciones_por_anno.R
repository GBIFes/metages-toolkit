#' Evolucion anual del numero de colecciones registradas
#'
#' Genera un grafico de barras que muestra, por año, el numero total
#' acumulado de colecciones registradas y el numero de colecciones
#' creadas en cada anno.
#'
#' Los datos se leen desde un archivo `.rds` incluido en el paquete
#' \pkg{metagesToolkit}, accedido a traves de la ruta indicada en
#' el argumento \code{rdspath}.
#'
#' @param rdspath Ruta al directorio que contiene el archivo
#'   \code{colecciones_per_anno.rds}.
#'
#' @return Un objeto \code{ggplot}.
#'
#'
#'
#' @seealso
#' \code{\link[ggplot2]{ggplot}}
#'
#' @examples
#' \dontrun{
#' crear_barplot_colecciones_por_anno(
#'   rdspath = "reports/data/vistas_sql"
#' )
#' }
#'
#' @export
crear_barplot_colecciones_por_anno <- function(rdspath) {
  
  ruta <- paste0(rdspath, "/colecciones_per_anno.rds")
  
  df <- readRDS(ruta)
  
  df_total <- df |>
    dplyr::filter(
      disciplina_def == "TOTAL GENERAL",
      !is.na(fecha_alta_coleccion)
    ) |>
    dplyr::mutate(
      acumulado = as.numeric(acumulado),
      total_colecciones = as.numeric(total_colecciones)
    )
  
  df_long <- tidyr::pivot_longer(
    df_total,
    cols = c(acumulado, total_colecciones),
    names_to = "tipo",
    values_to = "valor"
  )
  
  ggplot2::ggplot(
    df_long,
    ggplot2::aes(
      x = fecha_alta_coleccion,
      y = valor,
      fill = tipo
    )
  ) +
    ggplot2::geom_col(
      position = ggplot2::position_dodge(width = 0.3),
      width = 0.85,
      alpha = 0.8
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = valor),
      position = ggplot2::position_dodge(width = 0.3),
      vjust = -0.3,
      size = 4
    ) +
    ggplot2::scale_x_continuous(
      breaks = function(x) x[as.numeric(x) %% 5 == 0],
      expand = ggplot2::expansion(mult = c(0, 0))
    )+
    ggplot2::scale_fill_manual(
      values = c(
        "acumulado" = "#2ECC9A",
        "total_colecciones" = "#3B6AA0"
      ),
      labels = c(
        "acumulado" = "Colecciones totales por a\u00f1o",
        "total_colecciones" = "Colecciones creadas por a\u00f1o"
      )
    ) +
    ggplot2::labs(
      x = "A\u00f1o",
      y = "N\u00ba colecciones",
      fill = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.major.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1,
        vjust = 1
      ),
      axis.text.y = ggplot2::element_text(size = 10),
      axis.title.y = ggplot2::element_text(size = 13)
    )
}
