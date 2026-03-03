library(httr2)
library(dplyr)
library(purrr)


# Esta funcion extrae datasets y nombres de instituciones de OBIS que han sido publicados
# total o parcialmente por entidades espanholas

# DEBERIA SERVIR PARA ESTANDARIZAR EL REGISTRO DE COLECCIONES


extraer_metadata_obis <- function(limit = 1000) {

  
  BASE <- "https://api.obis.org/v3"
  
  # 1) Instituciones del país
  instituciones <- request(paste0(BASE, "/institute")) |>
    req_url_query(countryid = 196) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE) |>
    purrr::pluck("results") |>
    as_tibble() |>
    select(instituteid = id, institute_name = name)
  
  if (nrow(instituciones) == 0) {
    return(tibble())
  }
  
  # 2) Datasets asociados
  tabla_final <- map_dfr(
    instituciones$instituteid,
    function(inst_id) {
      
      request(paste0(BASE, "/dataset")) |>
        req_url_query(instituteid = inst_id, limit = limit) |>
        req_perform() |>
        resp_body_json(simplifyVector = TRUE) |>
        purrr::pluck("results") |>
        as_tibble() |>
        mutate(instituteid = inst_id)
    }
  ) |>
    left_join(instituciones, by = "instituteid")
  
  tabla_final
}


obis_spain <- extraer_metadata_obis()
