#' Crear grafico de top colecciones por número de registros
#'
#' Genera un grafico de barras horizontales con las 10 colecciones
#' con mayor numero de registros que publican en GBIF, a partir
#' de un objeto leido desde un archivo `.rds` interno de metagesToolkit.
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
  
  data <- readRDS(rds_path)
  
  # ---- caso 1: colecciones que publican en GBIF ----
  df_pub <- data %>%
    filter(
      publica_en_gbif == 1,
      !is.na(numberOfRecords),
      numberOfRecords > 0
    ) %>%
    arrange(desc(numberOfRecords)) %>%
    transmute(
      collection_code = coalesce(collection_code, coleccion_base),
      value = numberOfRecords
    ) %>%
    distinct()
  
  if (nrow(df_pub) >= 10) {
    
    df <- df_pub %>%
      head(10)
    
    x_label <- "N\u00BA registros"
    
  } else {
    
    # ---- fallback: todas las colecciones por subunidades ----
    df <- data %>%
      filter(
        !is.na(number_of_subunits),
        number_of_subunits > 0
      ) %>%
      arrange(desc(number_of_subunits)) %>%
      transmute(
        collection_code = coalesce(collection_code, coleccion_base),
        value = number_of_subunits
      ) %>%
      distinct() %>%
      head(10)
    
    x_label <- "N\u00BA de ejemplares"
  }
  
  plot <- ggplot(
    df,
    aes(
      x = value,
      y = reorder(collection_code, value)
    )
  ) +
    geom_col(
      width = 0.5,
      fill = "#2ECC9A",
      alpha = 0.8
    ) +
    geom_text(
      aes(
        label = scales::label_number(
          big.mark = ".",
          decimal.mark = ","
        )(value)
      ),
      hjust = -0.05,
      size = 3
    ) +
    labs(
      x = x_label,
      y = "C\u00F3digo de la colecci\u00F3n"
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
