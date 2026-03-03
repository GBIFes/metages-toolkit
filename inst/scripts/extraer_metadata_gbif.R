library(httr2)
library(dplyr)
library(purrr)


# Esta funcion extrae datasets e instituciones de GBIF.org espanholas.

# DEBERIA SERVIR PARA ESTANDARIZAR EL REGISTRO DE COLECCIONES


extraer_metadata_gbif <- function(page_limit = 300) {
  BASE <- "https://api.gbif.org/v1"
  
  # 1) Publishers españoles (tal como tu query de gbif.org/publisher/search?country=ES)
  publishers <- request(paste0(BASE, "/organization")) |>
    req_url_query(country = "ES", type = "PUBLISHER", limit = 1000) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE) |>
    purrr::pluck("results") |>
    as_tibble() |>
    transmute(
      publishingOrg = key,
      publisher_name = title
    )
  
  # 2) Datasets cuyos publishers están en ES (¡ojo! endpoint /dataset/search)
  offset <- 0
  pages <- list()
  
  repeat {
    message("Descargando datasets... offset = ", offset)
    
    res <- request(paste0(BASE, "/dataset/search")) |>
      req_url_query(
        publishingCountry = "ES",
        limit = page_limit,
        offset = offset
      ) |>
      req_perform() |>
      resp_body_json(simplifyVector = TRUE)
    
    if (length(res$results) == 0) break
    
    pages[[length(pages) + 1]] <- as_tibble(res$results)
    
    offset <- offset + page_limit
    if (!is.null(res$count) && offset >= res$count) break
  }
  
  datasets_es <- bind_rows(pages) |>
    mutate(publishingOrg = publishingOrganizationKey)
  
  # 3) Join final
  tabla_final <- datasets_es |>
    full_join(publishers, by = "publishingOrg")
  
  tabla_final
}


gbiforg_spain <- extraer_metadata_gbif()
