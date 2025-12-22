#######################################################################
# Title: Script to extract the IPT resource URL and data associated
#
# Created by: Ruben Perez Perez (GBIF.ES) 
# Creation Date: Tue Dec  2 09:43:21 2025
#######################################################################

# Instalar y cargar paquetes packages
pkgs <- c("rgbif", "purrr", "dplyr")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}

# Extraer datasetKeys
datasets <- dataset_search(publishingCountry = "ES",
                           type = c("OCCURRENCE", "SAMPLING_EVENT"),
                           limit = 1000)$data %>%
            select(datasetKey, title, publishingOrganizationTitle,
                   occurrenceRecordsCount)

# Añadir IPT resource URL
get_ipt_endpoint <- function(key) {

  ep <- dataset_endpoint(key)
  
  # si no hay endpoints, devolvemos NA
  if (is.null(ep) || nrow(ep) == 0) return(NA_character_)
  
  # nos quedamos con endpoints de archivo DwC-A
  ipt <- ep %>%
    dplyr::filter(type == "DWC_ARCHIVE")
  
  if (nrow(ipt) == 0) return(NA_character_)
  
  # si hay varios, cogemos el primero
  ipt$url[1]
}

# esto hará una llamada a la API por datasetKey
datasets$ipt_url <- map_chr(datasets$datasetKey, get_ipt_endpoint)
