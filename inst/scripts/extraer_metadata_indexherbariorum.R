library(httr2)
library(dplyr)
library(purrr)
library(tibble)


# Esta funcion extrae herbarios espanholes registrados en Index Herbariorum,
# el directorio mundial de herbarios de plantas vasculares y no vasculares.
# URL: https://sweetgum.nybg.org/science/ih/

# DEBERIA SERVIR PARA ESTANDARIZAR EL REGISTRO DE COLECCIONES BOTANICAS


extraer_metadata_indexherbariorum <- function(pais = "Spain") {

  BASE <- "https://sweetgum.nybg.org/science/api/v1/institutions"

  pagina <- 1
  paginas <- list()

  repeat {
    message("Descargando herbarios de Index Herbariorum... pagina = ", pagina)

    res <- request(BASE) |>
      req_url_query(country = pais, page = pagina) |>
      req_perform() |>
      resp_body_json(simplifyVector = TRUE)

    data <- res$data

    if (is.null(data) || (is.data.frame(data) && nrow(data) == 0) || length(data) == 0) break

    paginas[[length(paginas) + 1]] <- as_tibble(data)

    total_pages <- res$meta$totalPages %||% 1
    if (pagina >= total_pages) break
    pagina <- pagina + 1
  }

  if (length(paginas) == 0) return(tibble())

  raw <- bind_rows(paginas)

  # Seleccionar y normalizar columnas de interes
  columnas_disponibles <- names(raw)

  raw |>
    transmute(
      ih_id             = if ("irn" %in% columnas_disponibles) irn else NA_character_,
      codigo_herbario   = if ("code" %in% columnas_disponibles) code else NA_character_,
      nombre            = if ("organization" %in% columnas_disponibles) organization else NA_character_,
      acronimo          = if ("acronym" %in% columnas_disponibles) acronym else NA_character_,
      ciudad            = if ("physCity" %in% columnas_disponibles) physCity else NA_character_,
      region            = if ("physState" %in% columnas_disponibles) physState else NA_character_,
      pais              = if ("physCountry" %in% columnas_disponibles) physCountry else NA_character_,
      latitud           = if ("lat" %in% columnas_disponibles) as.numeric(lat) else NA_real_,
      longitud          = if ("lon" %in% columnas_disponibles) as.numeric(lon) else NA_real_,
      website           = if ("webUrls" %in% columnas_disponibles) webUrls else NA_character_,
      email             = if ("email" %in% columnas_disponibles) email else NA_character_,
      num_especimenes   = if ("specimenTotal" %in% columnas_disponibles) as.integer(specimenTotal) else NA_integer_
    )
}


indexherbariorum_spain <- extraer_metadata_indexherbariorum("Spain")
