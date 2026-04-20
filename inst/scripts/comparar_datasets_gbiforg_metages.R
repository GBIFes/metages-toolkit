library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(DBI)
library(tibble)
library(metagesToolkit)

comparar_datasets_gbiforg_metages <- function(con = conectar_metages()$con) {
  
  # ------------------------------------------------------------
  # 1) Obtener nº de occurrences por dataset en GBIF
  # ------------------------------------------------------------
  message("Extrayendo numero de registros por dataset...")
  resp_occ <- request("https://api.gbif.org/v1/occurrence/search") |>
    req_url_query(
      publishing_country = "ES",
      facet = "datasetKey",
      facetMincount = 1,
      limit = 0,
      `datasetKey.facetLimit` = 100000
    ) |>
    req_perform()
  
  occ_json <- resp_occ |>
    resp_body_string() |>
    fromJSON(flatten = TRUE)
  
  facets_df <- occ_json$facets$counts[[1]] |>
    transmute(
      dataset_id = name,
      n_occurrences = as.integer(count)
    )
  
  # ------------------------------------------------------------
  # 2) Resolver nombre de dataset en GBIF
  # ------------------------------------------------------------
  message("Resolviendo nombres de datasets...")
  get_dataset_name <- function(dataset_key) {
    url_dataset <- paste0("https://api.gbif.org/v1/dataset/", dataset_key)
    
    tryCatch({
      resp <- request(url_dataset) |>
        req_perform()
      
      dat <- resp |>
        resp_body_string() |>
        fromJSON(flatten = TRUE)
      
      if (!is.null(dat$title) && nzchar(dat$title)) dat$title else NA_character_
    }, error = function(e) {
      NA_character_
    })
  }
  
  gbif_df <- facets_df |>
    mutate(dataset_name = map_chr(dataset_id, get_dataset_name)) |>
    select(dataset_id, dataset_name, n_occurrences) |>
    arrange(desc(n_occurrences))
  
  # ------------------------------------------------------------
  # 3) Cargar datasets de MetaGES
  # ------------------------------------------------------------
  message("Cargando registro de MetaGES...")
  metages_df <- dbGetQuery(
    con,
    "SELECT recurso_id, uuid, title, numberOfRecords
     FROM metages_recurso"
  ) |>
    as_tibble() |>
    mutate(
      uuid = trimws(uuid),
      title = trimws(title)
    ) |>
    filter(!is.na(uuid), uuid != "")
  
  message("Comparando datos...")
  # ------------------------------------------------------------
  # 4) Datasets GBIF que NO están en MetaGES
  # ------------------------------------------------------------
  no_en_metages <- gbif_df |>
    anti_join(
      metages_df |> select(uuid),
      by = c("dataset_id" = "uuid")
    ) |>
    arrange(desc(n_occurrences))
  
  # ------------------------------------------------------------
  # 5) Datasets GBIF que SÍ están en MetaGES, con comparación
  # ------------------------------------------------------------
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
      diferencia_records
    ) |>
    arrange(desc(abs(diferencia_records)), desc(n_occurrences))
  
  # ------------------------------------------------------------
  # 6) Resumen
  # ------------------------------------------------------------
  resumen <- tibble(
    metric = c(
      "datasets_gbif",
      "datasets_metages_con_uuid",
      "datasets_gbif_no_en_metages",
      "datasets_gbif_si_en_metages",
      "titles_distintos",
      "numberOfRecords_distintos"
    ),
    value = c(
      nrow(gbif_df),
      nrow(metages_df),
      nrow(no_en_metages),
      nrow(en_metages),
      sum(!en_metages$title_coincide, na.rm = TRUE),
      sum(!en_metages$records_coinciden, na.rm = TRUE)
    )
  )
  
  list(
    resumen = resumen,
    gbif = gbif_df,
    no_en_metages = no_en_metages,
    en_metages = en_metages
  )
}