#' Evolucion anual de registros GBIF por naturaleza (Observaciones vs Especimenes)
#'
#' Genera dos graficos comparativos de la evolucion anual del numero de registros
#' publicados en GBIF.ES, diferenciando entre:
#'
#' \itemize{
#'   \item \strong{Observaciones} (HUMAN_OBSERVATION, MACHINE_OBSERVATION, OBSERVATION)
#'   \item \strong{Especimenes} (PRESERVED_SPECIMEN, MATERIAL_SAMPLE, FOSSIL_SPECIMEN)
#' }
#'
#' La funcion descarga los datos una unica vez mediante \pkg{galah} y construye:
#'
#' \enumerate{
#'   \item Un grafico en escala lineal con doble eje Y (ajustado mediante factor de escala).
#'   \item Un grafico en escala logaritmica (log10) con eje unico.
#' }
#'
#' Ademas, devuelve el conjunto de datos agregado en formato ancho para su reutilizacion.
#'
#' @param year_ini Anno inicial (inclusive) a partir del cual se recuperan los registros.
#'   Por defecto, 1840.
#' @param year_fin Anno final (inclusive). Por defecto, el anno actual.
#'
#' @return Una lista con tres elementos:
#' \describe{
#'   \item{lineal}{Objeto \code{ggplot} con grafico en escala lineal y doble eje Y.}
#'   \item{log}{Objeto \code{ggplot} con grafico en escala logaritmica (log10).}
#'   \item{data}{\code{data.frame} en formato ancho con columnas:
#'     \code{year}, \code{Observaciones}, \code{Especimenes}.}
#' }
#'
#' @details
#' Los datos se obtienen dinamicamente desde el nodo \strong{GBIF.ES}
#' utilizando \pkg{galah}. El grafico en escala lineal aplica un factor de
#' escalado para visualizar conjuntamente series de magnitudes diferentes
#' mediante un eje secundario.
#'
#' En el grafico logaritmico ambas series comparten el mismo eje transformado
#' con \code{scale_y_log10()}, lo que permite comparar tendencias relativas
#' sin necesidad de doble eje.
#'
#' La funcion requiere que las credenciales esten disponibles en las variables
#' de entorno:
#' \itemize{
#'   \item \code{ala_es_user}
#'   \item \code{ala_es_pw}
#' }
#'
#' @seealso
#' \code{\link[galah]{galah_call}},
#' \code{\link[ggplot2]{ggplot}},
#' \code{\link[ggplot2]{geom_area}}
#'
#' @examples
#' \dontrun{
#' plots <- crear_plots_evolucion_basisOfRecord()
#'
#' # Grafico en escala lineal
#' plots$lineal
#'
#' # Grafico en escala logaritmica
#' plots$log
#'
#' # Datos agregados
#' head(plots$data)
#' }
#'
#' @import dplyr
#' @import tidyr
#' @import ggplot2
#' @importFrom galah galah_config galah_call galah_filter 
#' @importFrom scales label_number
#' @importFrom grid unit
#'
#' @export

crear_plots_evolucion_basisOfRecord <- function(
    year_ini = 1840,
    year_fin = as.integer(format(Sys.Date(), "%Y"))
) {
  
  # =========================
  # 1. Configuracion
  # =========================
  galah_config(
    atlas = "GBIF.ES",
    email = Sys.getenv("ala_es_user"),
    password = Sys.getenv("ala_es_pw")
  )
  
  # =========================
  # 2. Descarga datos 
  # =========================
  datos_raw <- galah_call() |>
    galah_filter(
      year >= year_ini,
      year <= year_fin
    ) |>
    group_by(year, basisOfRecord) |>
    count() |>
    collect()
  
  valores_especimen <- c(
    "PRESERVED_SPECIMEN",
    "MATERIAL_SAMPLE",
    "FOSSIL_SPECIMEN"
  )
  
  valores_observacion <- c(
    "HUMAN_OBSERVATION",
    "MACHINE_OBSERVATION",
    "OBSERVATION"
  )
  
  # =========================
  # 3. Preparar datos en formato ancho (valores absolutos)
  # =========================
  datos_wide <- datos_raw |>
    mutate(
      year = as.integer(year),
      tipo = case_when(
        basisOfRecord %in% valores_especimen   ~ "Especimenes",
        basisOfRecord %in% valores_observacion ~ "Observaciones",
        TRUE ~ NA_character_
      )
    ) |>
    filter(!is.na(tipo)) |>
    group_by(year, tipo) |>
    summarise(n = sum(count), .groups = "drop") |>
    pivot_wider(
      names_from = tipo,
      values_from = n,
      values_fill = 0
    ) |>
    arrange(year)
  
  # =========================
  # 4. Calculo escalado doble eje
  # =========================
  max_obs  <- max(datos_wide$Observaciones, na.rm = TRUE)
  max_spec <- max(datos_wide$Especimenes, na.rm = TRUE)
  scale_factor <- max_obs / max_spec
  
  datos_plot <- datos_wide |>
    mutate(
      Especimenes_scaled = Especimenes * scale_factor
    )
  
  # =========================
  # 5. Plot 1: Escala lineal con doble eje
  # =========================
  plot_lineal <- ggplot(datos_plot, aes(x = year)) +
    
    geom_area(
      aes(y = Observaciones, fill = "Observaciones"),
      alpha = 0.8
    ) +
    
    geom_area(
      aes(y = Especimenes_scaled, fill = "Especimenes"),
      alpha = 0.8
    ) +
    
    scale_y_continuous(
      name = "N\u00BA registros (Observaciones)",
      labels = scales::label_number(big.mark = ".", decimal.mark = ","),
      sec.axis = sec_axis(
        ~ . / scale_factor,
        name = "N\u00BA registros (Espec\u00edmenes)",
        labels = scales::label_number(big.mark = ".", decimal.mark = ",")
      ),
      expand = c(0, 0)
    ) +
    
    scale_x_continuous(
      name = "A\u00f1o",
      breaks = seq(
        year_ini - year_ini %% 20,
        year_fin,
        by = 20
      )
    ) +
    
    scale_fill_manual(
      name = NULL,
      values = c(
        "Observaciones" = "#0A5DBB",
        "Especimenes" = "#3EE0A1"
      ),
      labels = c(
        "Observaciones" = "Observaciones",
        "Especimenes"   = "Espec\u00edmenes"
      ),
      breaks = c("Observaciones", "Especimenes")
    ) +
    
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "top",
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.title.y = element_text(margin = margin(r = 15)),
      axis.title.y.right = element_text(angle = 90,
                                                 margin = margin(l = 15)),
      axis.ticks.x = element_line(color = "grey"),
      axis.ticks.length = grid::unit(0.1, "cm")
    )
  
  # =========================
  # 6. Plot 2: Escala logaritmica (sin doble eje)
  # =========================
  plot_log <- ggplot(datos_wide, aes(x = year)) +
    
    # Observaciones primero (detras)
    geom_area(
      aes(y = Observaciones, fill = "Observaciones"),
      alpha = 0.8
    ) +
    
    # Especimenes despues (delante)
    geom_area(
      aes(y = Especimenes, fill = "Especimenes"),
      alpha = 0.8
    ) +
    
    scale_y_log10(
      name = "N\u00BA registros (log10)",
      labels = scales::label_number(big.mark = ".", decimal.mark = ","),
      expand = c(0, 0)
    ) +
    
    scale_x_continuous(
      name = "A\u00f1o",
      breaks = seq(
        year_ini - year_ini %% 20,
        year_fin,
        by = 20
      )
    ) +
    
    scale_fill_manual(
      name = NULL,
      values = c(
        "Observaciones" = "#0A5DBB",
        "Especimenes" = "#3EE0A1"
      ),
      labels = c(
        "Observaciones" = "Observaciones",
        "Especimenes"   = "Espec\u00edmenes"
      ),
      breaks = c("Observaciones", "Especimenes")
    ) +
    
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "top",
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.ticks.x = element_line(color = "grey"),
      axis.ticks.length = grid::unit(0.1, "cm")
    )
  
  
  # =========================
  # 7. Devolver ambos
  # =========================
  list(
    lineal = plot_lineal,
    log = plot_log,
    data = datos_wide
  )
}
