
# ------------------
# ------------------
      OBSOLETO
# ------------------
# ------------------

#' Evolución anual de los registros GBIF publicados por España
#'
#' Genera un gráfico de áreas que muestra, por año, el número de registros
#' publicados en GBIF por España y su acumulado total.
#'
#' El gráfico representa:
#' \itemize{
#'   \item el número de registros publicados cada año (en millones),
#'   \item el número acumulado total de registros publicados hasta ese año.
#' }
#'
#' Los datos se obtienen dinámicamente desde GBIF utilizando el paquete
#' \pkg{galah}, filtrando por país publicador (\code{publishingCountry = "ES"})
#' y por el año máximo indicado.
#'
#' @param year_fin Año final (inclusive) hasta el cual se recuperan los
#'   registros. Por defecto, el año actual.
#'
#' @return Un objeto \code{ggplot} que representa la evolución anual y
#'   acumulada del número de registros publicados por España en GBIF.
#'
#' @details
#' El número de registros se presenta en millones para facilitar la lectura.
#' El acumulado se calcula como la suma progresiva de los registros anuales.
#'
#' El gráfico utiliza áreas superpuestas para representar ambas series y
#' muestra una etiqueta con el total acumulado en el último año disponible.
#'
#' @seealso
#' \code{\link[galah]{galah_call}},
#' \code{\link[ggplot2]{ggplot}},
#' \code{\link[ggplot2]{geom_area}}
#'
#' @examples
#' \dontrun{
#' p <- crear_area_registros_gbif_es(year_fin = 2023)
#' print(p)
#' }
#'
#' @import dplyr
#' @import ggplot2
#' @import galah
#'
#' @export


crear_plot_evolucion_registros <- function(){

# ------------------
# Configuración GBIF
# ------------------
galah_config(atlas = "GBIF",
             email = Sys.getenv("ala_es_user"),
             password = Sys.getenv("ala_es_pw"))

# ------------------
# Parámetros
# ------------------
  year_ini <- 1870
  year_fin <- as.integer(format(Sys.Date(), "%Y"))
pais     <- "ES"

# ------------------
# 1. Registros aportados por año (España)
# ------------------
reg_anuales <- galah_call() |>
  galah_filter(year <= year_fin,
               publishingCountry == pais) |>
  group_by(year) |>
  count() |>
  collect() |>
  transmute(
    year = as.integer(year),
    registros_anio = count
  ) |>
  arrange(year)


# ------------------
# 2. Acumulado y transformacion a millones
# ------------------
reg_anuales <- reg_anuales |>
  mutate(
    registros_totales = cumsum(registros_anio),
    registros_anio_m = registros_anio / 1e6,
    registros_totales_m = registros_totales / 1e6
  )

# ------------------
# 3. Gráfico
# ------------------
ultimo <- tail(reg_anuales, 1)

ggplot(reg_anuales, aes(x = year)) +
  
  # Área acumulada
  geom_area(
    aes(y = registros_totales_m, fill = "Total acumulado"),
    alpha = 0.9
  ) +
  
  # Área por año
  geom_area(
    aes(y = registros_anio_m, fill = "N\u00ba registros por año"),
    alpha = 1
  ) +
  
  # Etiqueta final
  geom_label(
    data = ultimo,
    aes(
      x = year - 2,
      y = registros_totales_m * 0.85,
      label = format(
        registros_totales,
        big.mark = ".",
        decimal.mark = ",",
        scientific = FALSE
      )
    ),
    fill = "#FF8C7A",
    color = "white",
    size = 4
  ) +
  
  # Eje Y
  scale_y_continuous(
    name = "N\u00ba registros publicados (millones)",
    expand = c(0, 0)
  ) +
  
  # Eje X (ticks cada 5 años)
  scale_x_continuous(
    name = "Año",
    breaks = seq(
      year_ini - year_ini %% 5,
      year_fin,
      by = 5
    )
  ) +
  
  # Colores + leyenda
  scale_fill_manual(
    name = NULL,
    values = c(
      "Total acumulado"   = "#3EE0A1",
      "N\u00ba registros por año" = "#0A5DBB"
    )
  ) +
  
  # Tema
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "top"
  )
}


crear_plot_evolucion_registros()
