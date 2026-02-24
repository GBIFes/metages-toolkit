#' Conteo de registros GBIF agregados por nivel taxonomico
#'
#' Genera una tabla con el numero de registros publicados en GBIF
#' por Espanha, agregados segun el campo indicado en \code{facet}.
#'
#' Incluye una fila adicional denominada TOTAL con la suma global
#' de registros.
#'
#' @details
#' Valores habituales para \code{taxonKey}:
#' \itemize{
#'   \item \code{1} = Animalia
#'   \item \code{6} = Plantae
#'   \item \code{5} = Fungi
#' }
#'
#' Valores habituales para \code{facet} (campos indexados en
#' el endpoint \code{/occurrence/count}):
#' \itemize{
#'   \item \code{"phylumKey"}
#'   \item \code{"classKey"}
#'   \item \code{"orderKey"}
#'   \item \code{"familyKey"}
#'   \item \code{"genusKey"}
#'   \item \code{"speciesKey"}
#'   \item \code{"kingdomKey"}
#' }
#'
#' Ejemplos de \code{basisOfRecord}:
#'
#' Especimenes:
#' \preformatted{
#' c("PRESERVED_SPECIMEN",
#'   "MATERIAL_SAMPLE",
#'   "FOSSIL_SPECIMEN")
#' }
#'
#' Observaciones:
#' \preformatted{
#' c("OBSERVATION",
#'   "HUMAN_OBSERVATION",
#'   "MACHINE_OBSERVATION")
#' }
#'
#' @param taxonKey Clave taxonomica base.
#' @param facet Campo de agregacion indexado.
#' @param basisOfRecord Vector de tipos de registro a incluir.
#'
#' @return Un tibble con dos columnas:
#' \describe{
#'   \item{Filo}{Nombre del taxon agregado.}
#'   \item{N registros}{Numero de registros formateado con separador de miles.}
#' }
#'
#' @examples
#' # Conteo por filo para animales
#' conteo_registros_por_taxon()
#'
#' # Conteo por clase para plantas
#' conteo_registros_por_taxon(
#'   taxonKey = 6,
#'   facet = "classKey"
#' )
#'
#' # Solo observaciones humanas
#' conteo_registros_por_taxon(
#'   basisOfRecord = c("HUMAN_OBSERVATION")
#' )
#'
#' @import dplyr 
#' @import tibble
#' @importFrom purrr map_dfr
#' @importFrom httr2 request req_perform resp_body_json
#' @importFrom tools toTitleCase
#' @importFrom rgbif occ_count
#' 
#' 
#' @export

conteo_registros_por_taxon <- function(
    taxonKey = NULL,
    facet = "phylumKey",
    basisOfRecord = c(
      "PRESERVED_SPECIMEN",
      "MATERIAL_SAMPLE",
      "FOSSIL_SPECIMEN"
    )
) {
  
  # Convertir vector a formato requerido por occ_count
  basis_string <- paste(basisOfRecord, collapse = ";")
  
  # 1. Conteo agregado
  res <- occ_count(
    facet = facet,
    taxonKey = taxonKey,
    publishingCountry = "ES",
    occurrenceStatus = "PRESENT",
    basisOfRecord = basis_string,
    facetLimit = 200
  )
  
  tabla <- transmute(
    res,
    taxonKeyFacet = as.numeric(.data[[facet]]),
    n_registros = as.numeric(count)
  )
  
  # 2. Resolver clave taxonomica a nombre cientifico
  taxa <- map_dfr(tabla$taxonKeyFacet, function(pk) {
    
    resp <- request(
      paste0("https://api.gbif.org/v1/species/", pk)
    ) |>
      req_perform() |>
      resp_body_json()
    
    tibble(
      taxonKeyFacet = pk,
      nombre = resp$canonicalName
    )
  })
  
  tabla <- tabla |>
    left_join(taxa, by = "taxonKeyFacet") |>
    select(nombre, n_registros) |>
    arrange(desc(n_registros))
  
  # 3. TOTAL antes del formateo
  total <- sum(tabla$n_registros, na.rm = TRUE)
  
  tabla <- bind_rows(
    tabla,
    tibble(
      nombre = "TOTAL",
      n_registros = total
    )
  )
  
  
  # 4. Determinar nombre dinamico de la primera columna
  etiquetas <- c(
    phylumKey  = "Filo",
    kingdomKey = "Reino",
    classKey   = "Clase",
    orderKey   = "Orden",
    familyKey  = "Familia",
    genusKey   = "G\u00e9nero",
    speciesKey = "Especie"
  )
  
  nombre_columna <- etiquetas[facet]
  
  if (is.na(nombre_columna) || length(nombre_columna) == 0) {
    nombre_columna <- gsub("Key$", "", facet)
    nombre_columna <- tools::toTitleCase(nombre_columna)
  }
  
  
  # 5. Formateo final
  tabla <- tabla |>
    mutate(
      n_registros = format(
        n_registros,
        big.mark = ".",
        decimal.mark = ",",
        scientific = FALSE
      )
    ) |>
    rename_with(
      ~ c(nombre_columna, "N\u00ba registros"),
      .cols = c(nombre, n_registros)
    ) |>
    mutate(
      across(
        .cols = everything(),
        .fns  = trimws
      )
    )
  
  return(tabla)
}
