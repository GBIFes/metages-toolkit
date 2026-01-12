#' Top 10 paises con mayor numero de registros en GBIF
#'
#' Obtiene los 10 paises con mayor numero de registros de ocurrencias
#' en GBIF a nivel global, usando la API de \pkg{rgbif}. Ademas,
#' calcula la posicion acumulada historica de cada pais hasta el final
#' de un año previo, configurable mediante el argumento \code{years_back},
#' lo que permite comparar la situacion actual con el ranking historico.
#'
#' Los nombres de los paises se devuelven en castellano usando
#' \pkg{countrycode}.
#'
#' @param years_back Entero no negativo que indica cuantos años hacia atras
#'   se debe calcular el ranking acumulado historico. Por ejemplo:
#'   \itemize{
#'     \item \code{years_back = 1}: hasta el final del año pasado.
#'     \item \code{years_back = 2}: hasta el final del año anterior al pasado (valor por defecto).
#'   }
#'
#' @details
#' La funcion realiza dos consultas independientes a la API de GBIF:
#' \itemize{
#'   \item Un conteo global actual de registros por pais mediante
#'   \code{occ_count_country()}.
#'   \item Un conteo acumulado histórico hasta el año de referencia
#'   (\code{año_actual - years_back}) utilizando facetas en
#'   \code{occ_search()}.
#' }
#'
#' La posicion historica se calcula a partir del ranking acumulado
#' (orden descendente de numero de registros).
#'
#' @return
#' Un \code{tibble} con las siguientes columnas:
#' \itemize{
#'   \item \code{pais}: nombre del pais en español.
#'   \item \code{iso2}: codigo ISO2 del pais
#'   \item \code{count}: numero actual de registros en GBIF.
#'   \item \code{posicion_prev_cum}: posicion en el ranking acumulado historico.
#'   \item \code{count_prev_cum}: numero acumulado de registros hasta el año de referencia.
#' }
#'
#' @note
#' Esta funcion realiza llamadas a la API publica de GBIF y requiere
#' conexion a Internet. En funcion de la carga del servidor, puede tardar
#' varios segundos o fallar de forma intermitente.
#'
#'
#' @import dplyr
#' @importFrom rgbif occ_count_country occ_search
#' @importFrom tibble as_tibble
#' @importFrom countrycode countrycode
#'
#' @examples
#' \dontrun{
#' # Ranking acumulado hasta el final del año pasado
#' top_countries <- get_top10_countries_rgbif(years_back = 1)
#'
#' # Ranking acumulado historico mas amplio
#' top_countries_long <- get_top10_countries_rgbif(years_back = 5)
#' }
#'
#' @export

get_top10_countries_rgbif <- function(years_back = 2) {
  
  
  # Sacar ranking de paises en GBIF por numero de registros publicados
  df <- occ_count_country() |>
    arrange(desc(count)) |>
    slice_head(n = 10) |>                    # seleccionar numero de paises a extraer (max 10)
    mutate(pais = countrycode(iso2, "iso2c", # traducir paises a castellano
                              "cldr.name.es" 
                              #,custom_dict = codelist
                              )) |>
    select(pais, iso2, count)
  
  
  # ranking ACUMULADO hasta fin de año previo
  prev_year <- as.integer(format(Sys.Date(), "%Y")) - as.integer(years_back) # Decide cuantos anhos atras
  
  # Saca datos de GBIF.org hasta anho seleccionado
  res_prev_cum <- occ_search(
    facet = "country",
    year  = sprintf("*,%d", prev_year),   # <= prev_year (acumulado historico)
    limit = 0,
    facetLimit = 30
  )
  
  # Formatea los datos
  prev_cum <- as_tibble(res_prev_cum$facets$country) |>
    transmute(iso2 = name, count_prev_cum = as.double(count)) |>
    arrange(desc(count_prev_cum)) |>
    mutate(posicion_prev_cum = dplyr::row_number()) |>
    select(iso2, posicion_prev_cum, count_prev_cum)
  
  # Unir la posición acumulada previa al top-10 actual
  top_countries <- df |>
    left_join(prev_cum, by = "iso2")
  
  
  top_countries
}





#' Top paises publicadores de datos en GBIF
#'
#' Obtiene los países con mayor numero de registros publicados en GBIF,
#' en funcion del pais del publicador (\emph{publishing country}),
#' utilizando facetas de la API de \pkg{rgbif}.
#'
#' Los nombres de los paises se devuelven en castellano.
#'
#' @param n Numero de paises a devolver. Por defecto, 10.
#' @param years_back Entero no negativo que indica cuantos años hacia atras
#'   se debe calcular el ranking acumulado historico. Por ejemplo:
#'   \itemize{
#'     \item \code{years_back = 1}: hasta el final del año pasado.
#'     \item \code{years_back = 2}: hasta el final del año anterior al pasado (valor por defecto).
#'   }
#' @param facet_limit Límite maximo de categorias devueltas por la faceta
#'   \code{publishingCountry}. Debe aumentarse si se desea asegurar
#'   cobertura completa a nivel global.
#'
#' @details
#' La funcion no descarga registros individuales de ocurrencias.
#' Utiliza exclusivamente facetas, lo que la hace eficiente para
#' resumenes agregados a gran escala.
#'
#' @return
#' Un \code{tibble} con las siguientes columnas:
#' \itemize{
#'   \item \code{publishingCountry}: codigo ISO2 del pais publicador.
#'   \item \code{count}: numero de registros publicados.
#'   \item \code{pais_publicador}: nombre del pais en castellano.
#' }
#'
#' @note
#' Esta funcion consulta la API publica de GBIF y requiere conexion
#' a Internet.
#'
#' @import dplyr
#' @importFrom rgbif occ_search
#' @importFrom countrycode countrycode
#'
#' @examples
#' \dontrun{
#' top_publishers <- get_top_publishing_countries_gbif()
#' top_publishers_20 <- get_top_publishing_countries_gbif(n = 20)
#' }
#'
#' @export

get_top_publishing_countries_gbif <- function(
    n = 10,
    years_back = 2,
    facet_limit = 300
) {
  
  stopifnot(
    length(n) == 1, n > 0,
    length(years_back) == 1, years_back >= 0
  )
  
  # ---- 1. Ranking ACTUAL ----
  res_now <- rgbif::occ_search(
    facet = "publishingCountry",
    limit = 0,
    facetLimit = facet_limit,
    occurrenceStatus = NULL
  )
  
  df_now <- res_now$facets$publishingCountry |>
    dplyr::transmute(
      publishingCountry = name,      # ISO2
      count = as.double(count),
      pais_publicador = countrycode::countrycode(
        publishingCountry, "iso2c", "cldr.name.es"
      )
    ) |>
    dplyr::arrange(dplyr::desc(count)) |>
    dplyr::slice_head(n = n)
  
  # ---- 2. Ranking HISTORICO acumulado ----
  prev_year <- as.integer(format(Sys.Date(), "%Y")) - as.integer(years_back)
  
  res_prev <- rgbif::occ_search(
    facet = "publishingCountry",
    year  = sprintf("*,%d", prev_year),
    limit = 0,
    facetLimit = facet_limit,
    occurrenceStatus = NULL
  )
  
  df_prev <- res_prev$facets$publishingCountry |>
    dplyr::transmute(
      publishingCountry = name,
      count_prev_cum = as.double(count)
    ) |>
    dplyr::arrange(dplyr::desc(count_prev_cum)) |>
    dplyr::mutate(posicion_prev_cum = dplyr::row_number()) |>
    dplyr::select(publishingCountry, posicion_prev_cum, count_prev_cum)
  
  # ---- 3. Union actual + historico ----
  dplyr::left_join(df_now, df_prev, by = "publishingCountry")
}
