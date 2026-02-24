#' Tabla resumen taxonomico de registros GBIF publicados por Espanha
#'
#' Genera una tabla resumen con el numero de registros publicados en GBIF.es, 
#' desglosados por reino y acompanhados del numero de clases,
#' ordenes, familias, generos y especies representadas en dichos registros.
#'
#' Los conteos taxonomicos se calculan utilizando facets del endpoint
#' \code{/occurrence/count}, por lo que respetan los filtros de pais,
#' estado de ocurrencia y \code{basisOfRecord}.
#'
#' Se adiciona una fila final denominada \strong{Total} con la suma
#' de todas las metricas numericas.
#'
#' @details
#' Ejemplos habituales de valores para \code{basisOfRecord}:
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
#' @param basisOfRecord Vector de tipos de registro a incluir.
#' Si es \code{NULL}, no se aplica filtro por tipo de registro.
#'
#' @return Un tibble con las siguientes columnas:
#' \describe{
#'   \item{Reino}{Nombre del reino taxonomico.}
#'   \item{NU+000BA registros}{numero total de registros publicados.}
#'   \item{NU+000BA clases}{numero de clases representadas en los registros.}
#'   \item{NU+000BA ordenes}{numero de ordenes representadas.}
#'   \item{NU+000BA familias}{numero de familias representadas.}
#'   \item{NU+000BA generos}{numero de generos representados.}
#'   \item{NU+000BA especies y taxones infraespecificos}{numero de especies representadas en los registros.}
#' }
#'
#' @examples
#' # Tabla usando todos los registros (sin filtrar por basisOfRecord)
#' \dontrun{
#' extraer_resumen_taxonomico_gbif()
#' }
#'
#' # Solo especimenes
#' \dontrun{
#' extraer_resumen_taxonomico_gbif(
#'   basisOfRecord = c("PRESERVED_SPECIMEN",
#'                     "MATERIAL_SAMPLE",
#'                     "FOSSIL_SPECIMEN")
#' )
#' }
#'
#' # Solo observaciones humanas
#' \dontrun{
#' extraer_resumen_taxonomico_gbif(
#'   basisOfRecord = "HUMAN_OBSERVATION"
#' )
#' }
#'
#' @importFrom rgbif occ_count
#' @import dplyr
#' @import tibble
#' @importFrom purrr map_dfr
#'
#' @export

extraer_resumen_taxonomico_gbif <- function(
    basisOfRecord = NULL
) {
  
  # ------------------------------------------------
  # 1. Preparar filtros
  # ------------------------------------------------
  basis_string <- paste(basisOfRecord, collapse = ";")
  
  # ------------------------------------------------
  # 2. Definir reinos a evaluar
  # ------------------------------------------------
  reinos <- tibble(
    nombre = c("Animalia","Plantae","Fungi","Chromista","Protozoa","Bacteria","Archaea","Viruses"),
    key = c(1,6,5,4,7,3,2,8)
  )
  
  # ------------------------------------------------
  # 3. Funcion auxiliar para contar facets
  # ------------------------------------------------
  count_facet <- function(facet, key) {
    

    occ_count(
      taxonKey = key,
      publishingCountry = "ES",
      occurrenceStatus = "PRESENT",
      basisOfRecord = basis_string,
      facet = facet,
      facetLimit = 200000
    ) %>% 
      nrow()
  }
  
  # ------------------------------------------------
  # 4. Construccion de la tabla por reino
  # ------------------------------------------------
  tabla <- map_dfr(1:nrow(reinos), function(i) {
    
    key <- reinos$key[i]
    
    tibble(
      Reino = reinos$nombre[i],
      registros = occ_count(
        taxonKey = key,
        publishingCountry = "ES",
        occurrenceStatus = "PRESENT",
        basisOfRecord = basis_string
      ),
      clases = count_facet("classKey", key),
      ordenes = count_facet("orderKey", key),
      familias = count_facet("familyKey", key),
      generos = count_facet("genusKey", key),
      especies_infra = count_facet("speciesKey", key)
      
    )
  })
  
  # ------------------------------------------------
  # 5. Anhadir fila TOTAL
  # ------------------------------------------------
  total <- tabla %>%
    summarise(across(where(is.numeric), sum))
  
  total$Reino <- "Total"
  
  tabla <- bind_rows(tabla, total)
  
  # ------------------------------------------------
  # 6. Formateo
  # ------------------------------------------------
  tabla <- tabla %>%
    mutate(
      across(
        where(is.numeric),
        ~ format(.x,
                 big.mark = ".",
                 decimal.mark = ",",
                 scientific = FALSE)
      )
    ) %>%
    mutate(
      across(
        everything(),
        trimws
      )
    ) %>% rename_with(
      ~ c( "N\u00ba registros",
      "N\u00ba clases",
      "N\u00ba \u00f3rdenes",
      "N\u00ba familias",
      "N\u00ba g\u00e9neros",
      "N\u00ba especies y taxones infraespec\u00edficos"),
      .cols = c(registros, clases, ordenes, familias, generos, especies_infra),
    )
  
  
  return(tabla)
}
