#' Crear gráfico de top colecciones por número de registros
#'
#' Genera un gráfico de barras horizontales con las 10 colecciones
#' con mayor número de registros que publican en GBIF, a partir
#' de un objeto leído desde un archivo `.rds` interno de metagesToolkit.
#'
#' @param rds_path Ruta al archivo `.rds` que contiene el mapa de colecciones.
#'
#' @return Un objeto \code{ggplot}.
#'
#' @import ggplot2
#' @import dplyr
#'
#' @export
crear_barplot_top_colecciones_pub <- function(rds_path) {
  
  df <- readRDS(rds_path) %>%
    filter(publica_en_gbif == 1) %>%
    head(10) %>%
    transmute(collection_code = coalesce(collection_code, coleccion_base), 
              numberOfRecords)
  
  plot <- ggplot(
    df,
    aes(
      x = numberOfRecords,
      y = reorder(collection_code, numberOfRecords)
    )
  ) +
    geom_col(
      width = 0.5,
      fill = "#2ecc71"
    ) +
    geom_text(
      aes(
        label = scales::label_number(
          big.mark = ".",
          decimal.mark = ","
        )(numberOfRecords)
      ),
      hjust = -0.05,
      size = 3
    ) +
    labs(
      x = "Nº registros",
      y = "Código de colección"
    ) +
    theme_minimal() +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.x  = element_blank(),
      axis.ticks.x = element_blank()
    )
  
  return(plot)
}
