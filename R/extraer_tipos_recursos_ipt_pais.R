#' Numero de juegos de datos por pais publicador divididos por tipo de recurso.
#'
#' Consulta la API del registro de GBIF para obtener el numero de datasets
#' publicados por un pais determinado, agrupados por tipo de dataset,
#' junto con el numero total de registros indexados en GBIF.
#'
#' Los tipos considerados son siempre:
#' \itemize{
#'   \item "Occurrence"
#'   \item "Checklist"
#'   \item "Sampling Event"
#'   \item "Metadata"
#' }
#'
#' @param country Codigo ISO2 del pais publicador (por defecto "ES").
#'
#' @return Un `data.frame` con tres columnas:
#' \describe{
#'   \item{type}{Tipo de dataset}
#'   \item{n_recursos}{Numero de datasets}
#'   \item{n_registros}{Numero total de registros publicados}
#' }
#' Incluye una fila final con los totales agregados.
#'
#' @details
#' La funcion utiliza la API publica del registro de GBIF:
#' \url{https://api.gbif.org/v1/dataset/search}
#'
#' El numero de registros corresponde al campo `recordCount`
#' reportado por GBIF para cada dataset.
#'
#' @examples
#' \dontrun{
#' extraer_tipos_recursos_ipt_pais("ES")
#' }
#'
#' @import jsonlite
#' @import httr
#' @import dplyr
#' @importFrom purrr map_dfr
#'
#' @export
extraer_tipos_recursos_ipt_pais <- function(country = "ES") {
  
  tipos_api <- c("OCCURRENCE", "CHECKLIST", "SAMPLING_EVENT", "METADATA")
  
  obtener_datasets_tipo <- function(tipo_api, country) {
    
    limit <- 100
    offset <- 0
    total <- Inf
    resultados <- list()
    
    while (offset < total) {
      
      res <- GET(
        "https://api.gbif.org/v1/dataset/search",
        query = list(
          publishingCountry = country,
          type = tipo_api,
          limit = limit,
          offset = offset
        )
      )
      
      stop_for_status(res)
      
      resp <- fromJSON(
        content(res, "text", encoding = "UTF-8")
      )
      
      total <- resp$count
      
      if (length(resp$results) == 0) break
      
      resultados[[length(resultados) + 1]] <- resp$results
      
      offset <- offset + limit
    }
    
    bind_rows(resultados)
  }
  
  datos <- map_dfr(tipos_api, obtener_datasets_tipo, country = country)
  
  if (nrow(datos) == 0) {
    return(data.frame(
      type = character(),
      n_recursos = integer(),
      n_registros = numeric()
    ))
  }
  
  datos <- datos |>
    mutate(
      recordCount = ifelse(is.na(recordCount), 0, recordCount)
    )
  
  tabla_resumen <- datos |>
    group_by(type) |>
    summarise(
      n_recursos = n(),
      n_registros = sum(recordCount, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Convertir a formato legible
  tabla_resumen$type <- gsub("_", " ", tabla_resumen$type)
  tabla_resumen$type <- tools::toTitleCase(tolower(tabla_resumen$type))
  
  tabla_final <- bind_rows(
    tabla_resumen,
    summarise(
      tabla_resumen,
      type = "TOTAL",
      n_recursos = sum(n_recursos),
      n_registros = sum(n_registros)
    )
  ) |> 
  rename_with(~ c("Tipo de juego de datos",
                  "N\u00ba de recursos",
                  "N\u00ba de registros publicados"),
                     .cols = c(type,
                               n_recursos,
                               n_registros))
  
  tabla_final
}
