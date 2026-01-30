#' Crear grafico de sectores (pie chart) a partir de tablas agregadas
#'
#' Genera un grafico de sectores que representa la proporcion relativa de
#' recursos o colecciones por categoria a partir de una tabla agregada.
#'
#'
#' @param rds_path Ruta a un archivo \code{.rds} que contiene un
#'   \code{data.frame} con los datos agregados.
#' @param categoria Nombre de la columna categórica (caracter) que define
#'   los sectores del grafico (disciplinas o sectores).
#' @param valor Nombre de la columna numérica que contiene el peso de cada
#'   categoría (por ejemplo, numero de recursos o colecciones).
#'
#' @details
#' La funcion espera datos ya agregados por categoria. Si existen varias filas
#' con la misma categoria, sus valores se suman internamente antes de calcular
#' las proporciones.
#'
#'
#' @return Un objeto \code{ggplot} que representa un grafico de sectores.
#'
#'
#' @examples
#' \dontrun{
#' crear_piechart(
#'  rds_path = ruta_a_archivo_rds,
#'  categoria = "sector",
#'  valor = "n_recursos")
#' }
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
crear_piechart <- function(rds_path, categoria, valor) {

  data <- readRDS(rds_path)
    
  stopifnot(
    is.data.frame(data),
    categoria %in% names(data),
    valor %in% names(data)
  )

  
  # --------------------------------------------------
  # 1. Limpieza y agregacion
  # --------------------------------------------------
  
  df <- data |>
    filter(.data[[categoria]] != "TOTAL") |>
    group_by(.data[[categoria]]) |>
    summarise(
      valor = sum(.data[[valor]], na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      pct_raw = valor / sum(valor) * 100,
      porcentaje = if_else(
        round(pct_raw) == 0,
        round(pct_raw, 1),
        round(pct_raw)
      ),
      etiqueta = paste0(porcentaje, "%")
    )
  
  # --- intercalar grande/pequeño ---
  # Orden intercalado para separar porciones pequeñas
  idx_desc <- order(df$valor, decreasing = TRUE)
  i <- 1; j <- length(idx_desc); idx <- integer(0)
  while (i <= j) {
    idx <- c(idx, idx_desc[i]); i <- i + 1
    if (i <= j) { idx <- c(idx, idx_desc[j]); j <- j - 1 }
  }
  df <- df[idx, , drop = FALSE]
  
  # Forzar ese orden en ggplot
  df[[categoria]] <- factor(df[[categoria]], levels = df[[categoria]])
  
  
  # --------------------------------------------------
  # 2. Grafico
  # --------------------------------------------------
  
  ggplot(
    df,
    aes(x = "", 
                 y = valor, 
                 fill = .data[[categoria]])
  ) +
    # Pie (sin leyenda)
    geom_col(
      width = 1,
      color = "grey70",
      linewidth = 0.6,
      show.legend = FALSE,
      alpha = 0.8
    ) +
    
    # Leyenda: puntos fantasma (no se ven en el panel)
    geom_point(
      aes(
        x = NA_real_,
        y = NA_real_,
        fill = .data[[categoria]]
      ),
      inherit.aes = FALSE,
      shape = 21,     # circulo relleno
      size = 5,
      show.legend = TRUE,
      na.rm = TRUE
    ) +
    
    coord_polar(theta = "y", clip = "off") +
    
    geom_text(
      aes(label = etiqueta),
      position = position_stack(vjust = 0.5),
      size = 4,
      fontface = "bold",
      color = "white"
    ) +
    
    scale_fill_manual(values = pal_categoria, drop = FALSE) +
    
    # Forzar que la leyenda muestre circulos rellenos y visibles
    guides(
      fill = guide_legend(
        override.aes = list(
          shape = 21,
          alpha = 0.8,        # visible en la leyenda aunque alpha=0 en el geom
          size  = 5,
          colour = "grey70" # borde del circulo (opcional)
        )
      )
    ) +
    
    theme_minimal() +
    theme(
      axis.title = element_blank(),
      axis.text  = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      legend.title = element_blank(),
      plot.background  = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
}


