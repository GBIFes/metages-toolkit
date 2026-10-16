library(httr2)
library(dplyr)
library(tibble)


# Esta funcion extrae instituciones espanholas con colecciones de biodiversidad de Wikidata
# mediante consultas SPARQL al endpoint publico de Wikidata.
# URL: https://www.wikidata.org

# Se consultan entidades que sean museos de ciencias naturales, herbarios,
# museos de historia natural o colecciones biologicas con vinculo a Espanha.

# DEBERIA SERVIR PARA ESTANDARIZAR EL REGISTRO DE INSTITUCIONES


extraer_metadata_wikidata <- function() {

  ENDPOINT <- "https://query.wikidata.org/sparql"

  # Consulta SPARQL: instituciones espanholas relevantes para biodiversidad
  # Tipos considerados:
  #   Q33506  = museum
  #   Q181916 = herbarium
  #   Q187552 = natural history museum
  #   Q62832  = observatory (optional inclusion)
  #   Q7075   = library (optional)
  #   Q856234 = biological collection

  sparql_query <- "
SELECT DISTINCT
  ?entidad
  ?entidadLabel
  ?pais
  ?paisLabel
  ?ciudad
  ?ciudadLabel
  ?tipo
  ?tipoLabel
  ?sitioWeb
  ?ror
  ?isni
  ?gbif_publisher
  ?grscioll_institution
WHERE {
  VALUES ?tipos {
    wd:Q33506
    wd:Q181916
    wd:Q187552
    wd:Q856234
    wd:Q3550045
  }
  ?entidad wdt:P31/wdt:P279* ?tipos .
  ?entidad wdt:P17 wd:Q29 .            # pais = Spain

  OPTIONAL { ?entidad wdt:P17 ?pais . }
  OPTIONAL { ?entidad wdt:P131 ?ciudad . }
  OPTIONAL { ?entidad wdt:P31 ?tipo . }
  OPTIONAL { ?entidad wdt:P856 ?sitioWeb . }
  OPTIONAL { ?entidad wdt:P6782 ?ror . }
  OPTIONAL { ?entidad wdt:P213 ?isni . }
  OPTIONAL { ?entidad wdt:P3562 ?gbif_publisher . }
  OPTIONAL { ?entidad wdt:P4090 ?grscioll_institution . }

  SERVICE wikibase:label {
    bd:serviceParam wikibase:language \"es,en\" .
  }
}
ORDER BY ?entidadLabel
"

  message("Consultando Wikidata via SPARQL...")

  res <- request(ENDPOINT) |>
    req_url_query(query = sparql_query, format = "json") |>
    req_headers(Accept = "application/sparql-results+json") |>
    req_user_agent("metagesToolkit/1.0 (https://github.com/GBIFes/metages-toolkit; info@gbif.es)") |>
    req_perform() |>
    resp_body_json(simplifyVector = FALSE)

  bindings <- res$results$bindings

  if (length(bindings) == 0) return(tibble())

  # Funcion auxiliar para extraer el valor de una variable SPARQL
  val <- function(binding, var) {
    v <- binding[[var]]
    if (is.null(v)) NA_character_ else v$value
  }

  tabla <- purrr::map_dfr(bindings, function(b) {
    tibble(
      wikidata_id          = val(b, "entidad"),
      nombre               = val(b, "entidadLabel"),
      pais_id              = val(b, "pais"),
      pais_nombre          = val(b, "paisLabel"),
      ciudad_id            = val(b, "ciudad"),
      ciudad_nombre        = val(b, "ciudadLabel"),
      tipo_id              = val(b, "tipo"),
      tipo_nombre          = val(b, "tipoLabel"),
      website              = val(b, "sitioWeb"),
      ror_id               = val(b, "ror"),
      isni_id              = val(b, "isni"),
      gbif_publisher_key   = val(b, "gbif_publisher"),
      grscioll_inst_id     = val(b, "grscioll_institution")
    )
  }) |>
    # Simplificar URLs de Wikidata a IDs cortos (ej. http://www.wikidata.org/entity/Q12345 -> Q12345)
    mutate(
      wikidata_id      = sub(".*entity/", "", wikidata_id),
      pais_id          = sub(".*entity/", "", pais_id),
      ciudad_id        = sub(".*entity/", "", ciudad_id),
      tipo_id          = sub(".*entity/", "", tipo_id)
    ) |>
    # Eliminar duplicados de entidad (puede haber multiples tipos por entidad)
    distinct(wikidata_id, .keep_all = TRUE)

  tabla
}


wikidata_spain <- extraer_metadata_wikidata()
