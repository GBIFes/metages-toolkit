library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(tibble)
library(stringr)
library(DBI)
library(metagesToolkit)

# ============================================================
# Helpers generales
# ============================================================

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

gbif_get_json <- function(url, query = list(), max_tries = 3, pause_base = 1) {
  for (i in seq_len(max_tries)) {
    out <- tryCatch({
      req <- request(url)
      
      if (length(query) > 0) {
        req <- do.call(req_url_query, c(list(.req = req), query))
      }
      
      req |>
        req_perform() |>
        resp_body_json(simplifyVector = TRUE)
    }, error = function(e) {
      NULL
    })
    
    if (!is.null(out)) {
      return(out)
    }
    
    Sys.sleep(pause_base * i)
  }
  
  NULL
}

compact_text <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(character())
  }
  
  x <- unlist(x, recursive = TRUE, use.names = FALSE)
  x <- as.character(x)
  x <- trimws(x)
  x <- x[!is.na(x) & nzchar(x)]
  unique(x)
}

collapse_unique <- function(x, sep = " | ") {
  x <- compact_text(x)
  if (length(x) == 0) NA_character_ else paste(x, collapse = sep)
}

safe_col <- function(df, col, default = NA_character_) {
  if (!is.data.frame(df) || !(col %in% names(df))) {
    return(rep(default, if (is.data.frame(df)) nrow(df) else 0))
  }
  df[[col]]
}

first_endpoint_url <- function(endpoints, type_wanted) {
  if (is.null(endpoints) || length(endpoints) == 0) {
    return(NA_character_)
  }
  
  eps <- tryCatch(as_tibble(endpoints), error = function(e) NULL)
  
  if (is.null(eps) || !all(c("type", "url") %in% names(eps))) {
    return(NA_character_)
  }
  
  val <- eps |>
    filter(.data$type == type_wanted) |>
    pull(.data$url) |>
    compact_text()
  
  if (length(val) == 0) NA_character_ else val[[1]]
}

# ============================================================
# Contactos y metadatos
# ============================================================

extraer_contactos_dataset <- function(contacts) {
  vacio <- tibble(
    contact_type = character(),
    organization = character(),
    country = character(),
    email = character(),
    homepage = character(),
    address = character(),
    city = character(),
    postal_code = character(),
    province = character()
  )
  
  if (is.null(contacts) || length(contacts) == 0) {
    return(vacio)
  }
  
  if (!is.data.frame(contacts)) {
    contacts <- tryCatch(as_tibble(contacts), error = function(e) NULL)
    if (is.null(contacts)) return(vacio)
  }
  
  tibble(
    contact_type = as.character(safe_col(contacts, "type")),
    organization = vapply(safe_col(contacts, "organization"), collapse_unique, character(1)),
    country = vapply(safe_col(contacts, "country"), collapse_unique, character(1)),
    email = vapply(safe_col(contacts, "email"), collapse_unique, character(1)),
    homepage = vapply(safe_col(contacts, "homepage"), collapse_unique, character(1)),
    address = vapply(safe_col(contacts, "address"), collapse_unique, character(1)),
    city = vapply(safe_col(contacts, "city"), collapse_unique, character(1)),
    postal_code = vapply(safe_col(contacts, "postalCode"), collapse_unique, character(1)),
    province = vapply(safe_col(contacts, "province"), collapse_unique, character(1))
  )
}

# ============================================================
# Señales de posible procedencia española
# ============================================================

detectar_senal_espanola <- function(
    contacts_tbl,
    title,
    description,
    eml_url,
    dwca_url
) {
  # Términos geográficos generales, no institucionales
  geo_terms_es <- c(
    "spain", "españa", "espana", "iberia", "iberian peninsula", "peninsula iberica",
    "andalucia", "andalucía", "aragon", "aragón", "asturias", "illes balears",
    "baleares", "canarias", "cantabria", "castilla y leon", "castilla y león",
    "castilla-la mancha", "catalunya", "cataluña", "catalonia", "extremadura",
    "galicia", "madrid", "murcia", "navarra", "nafarroa", "la rioja",
    "euskadi", "pais vasco", "país vasco", "valencia", "comunitat valenciana",
    "alicante", "albacete", "almeria", "almería", "avila", "ávila", "badajoz",
    "barcelona", "burgos", "caceres", "cáceres", "cadiz", "cádiz", "castellon",
    "castellón", "ciudad real", "cordoba", "córdoba", "cuenca", "girona",
    "gerona", "granada", "guadalajara", "guipuzcoa", "guipúzcoa", "gipuzkoa",
    "huelva", "huesca", "jaen", "jaén", "a coruña", "la coruna", "leon", "león",
    "lleida", "lerida", "lugo", "malaga", "málaga", "murcia", "ourense", "orense",
    "palencia", "pontevedra", "salamanca", "segovia", "sevilla", "soria",
    "tarragona", "teruel", "toledo", "valencia", "valladolid", "bizkaia",
    "vizcaya", "zamora", "zaragoza"
  )
  
  txt <- c(
    title,
    description,
    contacts_tbl$organization,
    contacts_tbl$country,
    contacts_tbl$email,
    contacts_tbl$homepage,
    contacts_tbl$address,
    contacts_tbl$city,
    contacts_tbl$province,
    contacts_tbl$postal_code,
    eml_url,
    dwca_url
  ) |>
    compact_text() |>
    paste(collapse = " || ") |>
    str_to_lower()
  
  # 1) País de contacto
  country_hit <- any(
    str_to_lower(contacts_tbl$country %||% character()) %in% c("es", "spain", "españa", "espana"),
    na.rm = TRUE
  )
  
  # 2) Dominios .es
  domain_hit <- str_detect(txt, "\\.es\\b")
  
  # 3) Código postal español (5 dígitos, primeras dos cifras 01-52)
  postal_hit <- str_detect(
    txt,
    "\\b(0[1-9]|[1-4][0-9]|5[0-2])[0-9]{3}\\b"
  )
  
  # 4) Términos geográficos españoles en texto
  geo_hit <- any(
    str_detect(
      txt,
      regex(paste(geo_terms_es, collapse = "|"), ignore_case = TRUE)
    )
  )
  
  # 5) Provincia o ciudad de contacto que encaje con España
  admin_hit <- any(
    str_detect(
      str_to_lower(paste(c(contacts_tbl$city, contacts_tbl$province), collapse = " || ")),
      regex(paste(geo_terms_es, collapse = "|"), ignore_case = TRUE)
    )
  )
  
  motivos <- c()
  if (country_hit) motivos <- c(motivos, "contact_country_ES")
  if (domain_hit) motivos <- c(motivos, "domain_es")
  if (postal_hit) motivos <- c(motivos, "postal_code_es")
  if (geo_hit) motivos <- c(motivos, "geo_text_es")
  if (admin_hit) motivos <- c(motivos, "admin_unit_es")
  
  tibble(
    possible_spanish_source = length(motivos) > 0,
    n_senales_es = length(motivos),
    motivo_sospecha = if (length(motivos) == 0) NA_character_ else paste(motivos, collapse = " | ")
  )
}

clasificar_prioridad_revision <- function(n_senales_es, n_occurrences_country) {
  case_when(
    is.na(n_senales_es) ~ "baja",
    n_senales_es >= 3 & !is.na(n_occurrences_country) & n_occurrences_country >= 100 ~ "alta",
    n_senales_es >= 3 ~ "alta",
    n_senales_es == 2 ~ "media",
    n_senales_es == 1 ~ "baja",
    TRUE ~ "baja"
  )
}

# ============================================================
# Descargas GBIF
# ============================================================

descargar_organizaciones_gbif <- function(base = "https://api.gbif.org/v1") {
  offset <- 0
  pages <- list()
  
  repeat {
    res <- gbif_get_json(
      paste0(base, "/organization"),
      query = list(limit = 1000, offset = offset)
    )
    
    if (is.null(res) || length(res$results) == 0) break
    
    pages[[length(pages) + 1]] <- as_tibble(res$results)
    offset <- offset + 1000
    
    if (!is.null(res$count) && offset >= res$count) break
  }
  
  bind_rows(pages) |>
    transmute(
      org_key = key,
      org_name = title,
      org_country = country
    ) |>
    distinct(org_key, .keep_all = TRUE)
}

descargar_datasets_busqueda <- function(
    q = NULL,
    publishing_country = NULL,
    page_limit = 300,
    base = "https://api.gbif.org/v1"
) {
  offset <- 0
  pages <- list()
  
  repeat {
    query <- list(limit = page_limit, offset = offset)
    
    if (!is.null(q)) query$q <- q
    if (!is.null(publishing_country)) query$publishingCountry <- publishing_country
    
    res <- gbif_get_json(
      paste0(base, "/dataset/search"),
      query = query
    )
    
    if (is.null(res) || length(res$results) == 0) break
    
    pages[[length(pages) + 1]] <- as_tibble(res$results)
    offset <- offset + page_limit
    
    if (!is.null(res$count) && offset >= res$count) break
  }
  
  bind_rows(pages)
}

descargar_occurrences_por_dataset_publicador <- function(
    publishing_country = "ES",
    base = "https://api.gbif.org/v1"
) {
  occ_json <- gbif_get_json(
    paste0(base, "/occurrence/search"),
    query = list(
      publishing_country = publishing_country,
      facet = "datasetKey",
      facetMincount = 1,
      limit = 0,
      `datasetKey.facetLimit` = 100000
    )
  )
  
  if (is.null(occ_json) || is.null(occ_json$facets$counts[[1]])) {
    return(tibble(dataset_id = character(), n_occurrences = integer()))
  }
  
  occ_json$facets$counts[[1]] |>
    as_tibble() |>
    transmute(
      dataset_id = name,
      n_occurrences = as.integer(count)
    )
}

descargar_datasets_con_occ_en_pais <- function(
    country = "ES",
    base = "https://api.gbif.org/v1"
) {
  occ_json <- gbif_get_json(
    paste0(base, "/occurrence/search"),
    query = list(
      country = country,
      facet = "datasetKey",
      facetMincount = 1,
      limit = 0,
      `datasetKey.facetLimit` = 100000
    )
  )
  
  if (is.null(occ_json) || is.null(occ_json$facets$counts[[1]])) {
    return(tibble(dataset_id = character(), n_occurrences_country = integer()))
  }
  
  occ_json$facets$counts[[1]] |>
    as_tibble() |>
    transmute(
      dataset_id = name,
      n_occurrences_country = as.integer(count)
    )
}

# ============================================================
# Detalle de datasets
# ============================================================

extraer_detalle_dataset <- function(
    dataset_key,
    base = "https://api.gbif.org/v1"
) {
  dat <- gbif_get_json(paste0(base, "/dataset/", dataset_key))
  
  if (is.null(dat)) {
    return(tibble(
      dataset_id = dataset_key,
      dataset_name = NA_character_,
      doi = NA_character_,
      dataset_type = NA_character_,
      publishing_org_key = NA_character_,
      hosting_org_key = NA_character_,
      installation_key = NA_character_,
      gbif_url = paste0("https://www.gbif.org/dataset/", dataset_key),
      dwca_endpoint = NA_character_,
      eml_endpoint = NA_character_,
      contact_organizations = NA_character_,
      contact_countries = NA_character_,
      contact_emails = NA_character_,
      contact_homepages = NA_character_,
      contact_addresses = NA_character_,
      contact_cities = NA_character_,
      contact_postal_codes = NA_character_,
      contact_provinces = NA_character_,
      possible_spanish_source = NA,
      n_senales_es = NA_integer_,
      motivo_sospecha = NA_character_
    ))
  }
  
  contacts_tbl <- extraer_contactos_dataset(dat$contacts)
  
  dwca_endpoint <- first_endpoint_url(dat$endpoints, "DWC_ARCHIVE")
  eml_endpoint  <- first_endpoint_url(dat$endpoints, "EML")
  
  senal <- detectar_senal_espanola(
    contacts_tbl = contacts_tbl,
    title = dat$title %||% NA_character_,
    description = dat$description %||% NA_character_,
    eml_url = eml_endpoint,
    dwca_url = dwca_endpoint
  )
  
  tibble(
    dataset_id = dataset_key,
    dataset_name = as.character(dat$title %||% NA_character_),
    doi = as.character(dat$doi %||% NA_character_),
    dataset_type = as.character(dat$type %||% NA_character_),
    publishing_org_key = as.character(dat$publishingOrganizationKey %||% NA_character_),
    hosting_org_key = as.character(dat$hostingOrganizationKey %||% NA_character_),
    installation_key = as.character(dat$installationKey %||% NA_character_),
    gbif_url = paste0("https://www.gbif.org/dataset/", dataset_key),
    dwca_endpoint = dwca_endpoint,
    eml_endpoint = eml_endpoint,
    contact_organizations = collapse_unique(contacts_tbl$organization),
    contact_countries = collapse_unique(contacts_tbl$country),
    contact_emails = collapse_unique(contacts_tbl$email),
    contact_homepages = collapse_unique(contacts_tbl$homepage),
    contact_addresses = collapse_unique(contacts_tbl$address),
    contact_cities = collapse_unique(contacts_tbl$city),
    contact_postal_codes = collapse_unique(contacts_tbl$postal_code),
    contact_provinces = collapse_unique(contacts_tbl$province),
    possible_spanish_source = senal$possible_spanish_source,
    n_senales_es = senal$n_senales_es,
    motivo_sospecha = senal$motivo_sospecha
  )
}

extraer_detalles_datasets <- function(
    dataset_ids,
    base = "https://api.gbif.org/v1"
) {
  dataset_ids <- unique(dataset_ids)
  dataset_ids <- dataset_ids[!is.na(dataset_ids) & nzchar(dataset_ids)]
  
  purrr::map_dfr(
    dataset_ids,
    ~ extraer_detalle_dataset(dataset_key = .x, base = base)
  )
}

# ============================================================
# MetaGES
# ============================================================

cargar_metages_datasets <- function(con) {
  dbGetQuery(
    con,
    "SELECT recurso_id, uuid, title, numberOfRecords
     FROM metages_recurso
     WHERE private = 0"
  ) |>
    as_tibble() |>
    mutate(
      uuid = trimws(uuid),
      title = trimws(title)
    ) |>
    filter(!is.na(uuid), uuid != "")
}

# ============================================================
# Función principal
# ============================================================

comparar_datasets_gbiforg_metages <- function(
    con = conectar_metages()$con
) {
  base <- "https://api.gbif.org/v1"
  
  message("Descargando organizaciones GBIF...")
  orgs_tbl <- descargar_organizaciones_gbif(base = base)
  
  # ------------------------------------------------------------
  # 1) Universo principal: publisher ES
  # ------------------------------------------------------------
  message("Descargando datasets con publisher ES...")
  datasets_pub_es <- descargar_datasets_busqueda(
    publishing_country = "ES",
    page_limit = 300,
    base = base
  ) |>
    transmute(dataset_id = key) |>
    distinct()
  
  message("Extrayendo numero de registros por dataset con publisher ES...")
  occ_pub_es_df <- descargar_occurrences_por_dataset_publicador(
    publishing_country = "ES",
    base = base
  )
  
  message("Resolviendo detalle de datasets con publisher ES...")
  gbif_meta <- extraer_detalles_datasets(
    dataset_ids = datasets_pub_es$dataset_id,
    base = base
  )
  
  gbif_df <- gbif_meta |>
    left_join(occ_pub_es_df, by = "dataset_id") |>
    left_join(
      orgs_tbl |>
        rename(
          publishing_org_key = org_key,
          publisher_name = org_name,
          publisher_country = org_country
        ),
      by = "publishing_org_key"
    ) |>
    left_join(
      orgs_tbl |>
        rename(
          hosting_org_key = org_key,
          hosting_org_name = org_name,
          hosting_org_country = org_country
        ),
      by = "hosting_org_key"
    ) |>
    mutate(
      publisher_es = publisher_country == "ES",
      hosting_es = hosting_org_country == "ES"
    ) |>
    arrange(desc(n_occurrences))
  
  # ------------------------------------------------------------
  # 2) Universo ampliado: datasets con ocurrencias en España
  # ------------------------------------------------------------
  message("Extrayendo datasets con ocurrencias en España...")
  occ_es_df <- descargar_datasets_con_occ_en_pais(
    country = "ES",
    base = base
  )
  
  # Candidatos = datasets con ocurrencias en ES que no están ya
  # en el universo de publisher ES
  candidate_ids <- occ_es_df |>
    anti_join(
      gbif_df |> select(dataset_id),
      by = "dataset_id"
    ) |>
    pull(dataset_id)
  
  message("Resolviendo detalle de candidatos con ocurrencias en España...")
  candidate_meta <- extraer_detalles_datasets(
    dataset_ids = candidate_ids,
    base = base
  )
  
  candidatos_publisher_posiblemente_mal <- candidate_meta |>
    left_join(
      orgs_tbl |>
        rename(
          publishing_org_key = org_key,
          publisher_name = org_name,
          publisher_country = org_country
        ),
      by = "publishing_org_key"
    ) |>
    left_join(
      orgs_tbl |>
        rename(
          hosting_org_key = org_key,
          hosting_org_name = org_name,
          hosting_org_country = org_country
        ),
      by = "hosting_org_key"
    ) |>
    left_join(
      occ_es_df,
      by = "dataset_id"
    ) |>
    mutate(
      publisher_es = publisher_country == "ES",
      hosting_es = hosting_org_country == "ES",
      posible_publisher_incorrecto = !publisher_es,
      prioridad_revision = clasificar_prioridad_revision(
        n_senales_es = n_senales_es,
        n_occurrences_country = n_occurrences_country
      )
    ) |>
    filter(
      !publisher_es,
      possible_spanish_source
    ) |>
    arrange(
      desc(n_senales_es),
      desc(n_occurrences_country)
    )
  
  # ------------------------------------------------------------
  # 3) MetaGES
  # ------------------------------------------------------------
  message("Cargando datasets de MetaGES...")
  metages_df <- cargar_metages_datasets(con)
  
  message("Comparando GBIF y MetaGES...")
  no_en_metages <- gbif_df |>
    anti_join(
      metages_df |> select(uuid),
      by = c("dataset_id" = "uuid")
    ) |>
    arrange(desc(n_occurrences))
  
  en_metages <- gbif_df |>
    inner_join(
      metages_df,
      by = c("dataset_id" = "uuid")
    ) |>
    mutate(
      title_coincide = dataset_name == title,
      records_coinciden = n_occurrences == numberOfRecords,
      diferencia_records = n_occurrences - numberOfRecords
    ) |>
    select(
      recurso_id,
      dataset_id,
      dataset_name,
      title,
      title_coincide,
      n_occurrences,
      numberOfRecords,
      records_coinciden,
      diferencia_records,
      publisher_name,
      publisher_country,
      hosting_org_name,
      hosting_org_country,
      gbif_url,
      dwca_endpoint,
      eml_endpoint,
      contact_organizations,
      contact_countries,
      contact_emails,
      contact_homepages,
      contact_addresses,
      contact_cities,
      contact_postal_codes,
      contact_provinces,
      possible_spanish_source,
      n_senales_es,
      motivo_sospecha
    ) |>
    arrange(desc(abs(diferencia_records)), desc(n_occurrences))
  
  # ------------------------------------------------------------
  # 4) Resumen
  # ------------------------------------------------------------
  resumen <- tibble(
    metric = c(
      "datasets_gbif_publisher_es",
      "datasets_metages_con_uuid",
      "datasets_gbif_no_en_metages",
      "datasets_gbif_si_en_metages",
      "titles_distintos",
      "numberOfRecords_distintos",
      "candidatos_origen_es_con_publisher_no_es"
    ),
    value = c(
      nrow(gbif_df),
      nrow(metages_df),
      nrow(no_en_metages),
      nrow(en_metages),
      sum(!en_metages$title_coincide, na.rm = TRUE),
      sum(!en_metages$records_coinciden, na.rm = TRUE),
      nrow(candidatos_publisher_posiblemente_mal)
    )
  )
  
  list(
    resumen = resumen,
    gbif = gbif_df,
    no_en_metages = no_en_metages,
    en_metages = en_metages,
    candidatos_publisher_posiblemente_mal = candidatos_publisher_posiblemente_mal,
    occ_es = occ_es_df
  )
}


x <- comparar_datasets_gbiforg_metages()
