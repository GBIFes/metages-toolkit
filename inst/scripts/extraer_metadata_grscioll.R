library(httr2)
library(dplyr)
library(purrr)
library(tibble)


# Esta funcion extrae instituciones y colecciones espanholas registradas en GrSciColl,
# el Registro Global de Colecciones Cientificas alojado en GBIF.
# URL: https://www.gbif.org/grscicoll

# DEBERIA SERVIR PARA ESTANDARIZAR EL REGISTRO DE COLECCIONES


extraer_metadata_grscioll <- function(pais = "ES") {

  BASE <- "https://api.gbif.org/v1/grscicoll"

  # 1) Instituciones espanholas en GrSciColl
  message("Descargando instituciones de GrSciColl...")

  offset_inst <- 0
  paginas_inst <- list()

  repeat {
    res_inst <- request(paste0(BASE, "/institution")) |>
      req_url_query(country = pais, limit = 100, offset = offset_inst) |>
      req_perform() |>
      resp_body_json(simplifyVector = TRUE)

    if (length(res_inst$results) == 0) break

    paginas_inst[[length(paginas_inst) + 1]] <- as_tibble(res_inst$results)

    offset_inst <- offset_inst + 100
    if (offset_inst >= (res_inst$count %||% 0)) break
  }

  instituciones <- if (length(paginas_inst) > 0) {
    raw_inst <- bind_rows(paginas_inst)
    cols_inst <- names(raw_inst)
    raw_inst |>
      transmute(
        grscioll_institution_id   = key,
        nombre                    = name,
        codigo                    = code,
        tipo                      = if ("type" %in% cols_inst) type else NA_character_,
        ciudad                    = if ("address.city" %in% cols_inst) address.city else NA_character_,
        pais_codigo               = pais,
        latitud                   = if ("latitude" %in% cols_inst) latitude else NA_real_,
        longitud                  = if ("longitude" %in% cols_inst) longitude else NA_real_,
        activo                    = if ("active" %in% cols_inst) active else NA,
        website                   = if ("homepage" %in% cols_inst) homepage else NA_character_
      )
  } else {
    tibble()
  }

  # 2) Colecciones espanholas en GrSciColl
  message("Descargando colecciones de GrSciColl...")

  offset_col <- 0
  paginas_col <- list()

  repeat {
    res_col <- request(paste0(BASE, "/collection")) |>
      req_url_query(country = pais, limit = 100, offset = offset_col) |>
      req_perform() |>
      resp_body_json(simplifyVector = TRUE)

    if (length(res_col$results) == 0) break

    paginas_col[[length(paginas_col) + 1]] <- as_tibble(res_col$results)

    offset_col <- offset_col + 100
    if (offset_col >= (res_col$count %||% 0)) break
  }

  colecciones <- if (length(paginas_col) > 0) {
    raw_col <- bind_rows(paginas_col)
    cols_col <- names(raw_col)
    raw_col |>
      transmute(
        grscioll_collection_id        = key,
        nombre                        = name,
        codigo                        = code,
        grscioll_institution_id       = if ("institutionKey" %in% cols_col) institutionKey else NA_character_,
        ciudad                        = if ("address.city" %in% cols_col) address.city else NA_character_,
        pais_codigo                   = pais,
        activo                        = if ("active" %in% cols_col) active else NA,
        descripcion                   = if ("description" %in% cols_col) description else NA_character_
      )
  } else {
    tibble()
  }

  list(
    instituciones = instituciones,
    colecciones   = colecciones
  )
}


grscioll_spain <- extraer_metadata_grscioll("ES")
