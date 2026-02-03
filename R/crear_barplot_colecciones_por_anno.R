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
#' @import dplyr
#' @import ggplot2
#' @import tidyr
#'
#'
#' @export
crear_barplot_colecciones_por_anno <- function(rdspath) {
  
  ruta <- paste0(rdspath, "/colecciones_per_anno.rds")
  
  df <- readRDS(ruta)
  
  df_total <- df |>
    filter(
      disciplina_def == "TOTAL GENERAL",
      !is.na(fecha_alta_coleccion)
    ) |>
    mutate(
      acumulado = as.numeric(acumulado),
      total_colecciones = as.numeric(total_colecciones)
    )
  
  df_long <- pivot_longer(
    df_total,
    cols = c(acumulado, total_colecciones),
    names_to = "tipo",
    values_to = "valor"
  )
  
  ggplot(
    df_long,
    aes(
      x = fecha_alta_coleccion,
      y = valor,
      fill = tipo
    )
  ) +
    geom_col(
      position = position_dodge(width = 0.3),
      width = 0.85,
      alpha = 0.8
    ) +
    geom_text(
      aes(label = valor),
      position = position_dodge(width = 0.3),
      vjust = -0.3,
      size = 4
    ) +
    scale_x_continuous(
      breaks = function(x) {
        seq(
          from = floor(min(x, na.rm = TRUE) / 5) * 5,
          to   = ceiling(max(x, na.rm = TRUE) / 5) * 5,
          by   = 5
        )
      },
      expand = expansion(mult = c(0, 0))
    ) +
    scale_fill_manual(
      values = c(
        "acumulado" = "#2ECC9A",
        "total_colecciones" = "#3B6AA0"
      ),
      labels = c(
        "acumulado" = "Colecciones totales por a\u00f1o",
        "total_colecciones" = "Colecciones creadas por a\u00f1o"
      )
    ) +
    labs(
      x = "A\u00f1o",
      y = "N\u00ba colecciones",
      fill = NULL
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      axis.text.x = element_text(
        angle = 45,
        hjust = 1,
        vjust = 1
      ),
      axis.text.y = element_text(size = 10),
      axis.title.y = element_text(size = 13)
    )
}
