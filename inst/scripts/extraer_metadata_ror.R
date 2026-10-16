library(httr2)
library(dplyr)
library(purrr)
library(tibble)


# Esta funcion extrae instituciones espanholas del Research Organization Registry (ROR).
# ROR es el registro canonico de identificadores para organizaciones de investigacion.
# URL: https://ror.org

# DEBERIA SERVIR PARA ESTANDARIZAR EL REGISTRO DE INSTITUCIONES


extraer_metadata_ror <- function(pais = "ES") {

  BASE <- "https://api.ror.org/v2/organizations"

  pagina <- 1
  paginas <- list()

  repeat {
    message("Descargando instituciones ROR... pagina = ", pagina)

    res <- request(BASE) |>
      req_url_query(
        query = paste0("country.country_code:", pais),
        page = pagina
      ) |>
      req_perform() |>
      resp_body_json(simplifyVector = FALSE)

    items <- res$items

    if (length(items) == 0) break

    pagina_df <- map_dfr(items, function(org) {
      tibble(
        ror_id        = org$id %||% NA_character_,
        nombre        = if (!is.null(org$names) && length(org$names) > 0) {
                          nombre_val <- purrr::keep(org$names, ~ "ror_display" %in% (.x$types %||% character()))
                          if (length(nombre_val) > 0) nombre_val[[1]]$value else org$names[[1]]$value
                        } else NA_character_,
        tipo          = if (!is.null(org$types) && length(org$types) > 0)
                          paste(org$types, collapse = "; ") else NA_character_,
        establecido   = org$established %||% NA_integer_,
        ciudad        = if (!is.null(org$locations) && length(org$locations) > 0)
                          org$locations[[1]]$geonames_details$name %||% NA_character_ else NA_character_,
        pais_codigo   = if (!is.null(org$locations) && length(org$locations) > 0)
                          org$locations[[1]]$geonames_details$country_code %||% NA_character_ else NA_character_,
        website       = if (!is.null(org$links) && length(org$links) > 0) {
                          website_val <- purrr::keep(org$links, ~ (.x$type %||% "") == "website")
                          if (length(website_val) > 0) website_val[[1]]$value else NA_character_
                        } else NA_character_,
        wikidata_id   = {
                          ext_ids <- org$external_ids %||% list()
                          wd <- purrr::keep(ext_ids, ~ (.x$type %||% "") == "wikidata")
                          if (length(wd) > 0 && length(wd[[1]]$all) > 0) wd[[1]]$all[[1]] else NA_character_
                        },
        isni_id       = {
                          ext_ids <- org$external_ids %||% list()
                          isni <- purrr::keep(ext_ids, ~ (.x$type %||% "") == "isni")
                          if (length(isni) > 0 && length(isni[[1]]$all) > 0) isni[[1]]$all[[1]] else NA_character_
                        },
        fundref_id    = {
                          ext_ids <- org$external_ids %||% list()
                          fr <- purrr::keep(ext_ids, ~ (.x$type %||% "") == "fundref")
                          if (length(fr) > 0 && length(fr[[1]]$all) > 0) fr[[1]]$all[[1]] else NA_character_
                        },
        estado        = org$status %||% NA_character_
      )
    })

    paginas[[length(paginas) + 1]] <- pagina_df

    # ROR v2: meta.total_results / page_size = 20
    total <- res$meta$total_results %||% 0
    if (pagina * 20 >= total) break
    pagina <- pagina + 1
  }

  if (length(paginas) == 0) return(tibble())

  bind_rows(paginas)
}


ror_spain <- extraer_metadata_ror("ES")
