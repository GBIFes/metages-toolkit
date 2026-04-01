library(dplyr)
library(tibble)
library(purrr)


# Este script construye una tabla de equivalencia de IDs entre los diferentes
# registros de instituciones y colecciones de biodiversidad de Espanha:
#   - ROR          (Research Organization Registry)
#   - GBIF.org     (organizaciones publicadoras espanholas)
#   - GrSciColl    (instituciones y colecciones del registro GBIF)
#   - Index Herbariorum
#   - OBIS         (instituciones asociadas a datasets espanholes)
#   - Wikidata
#
# PREREQUISITO: ejecutar previamente los scripts de extraccion:
#   inst/scripts/extraer_metadata_ror.R
#   inst/scripts/extraer_metadata_gbif.R
#   inst/scripts/extraer_metadata_grscioll.R
#   inst/scripts/extraer_metadata_indexherbariorum.R
#   inst/scripts/extraer_metadata_obis.R
#   inst/scripts/extraer_metadata_wikidata.R
#
# Los objetos resultantes de esos scripts deben estar en el entorno de R:
#   ror_spain, gbiforg_spain, grscioll_spain, indexherbariorum_spain,
#   obis_spain, wikidata_spain


# ============================================================
# Funcion auxiliar: normalizar nombres para vinculacion fuzzy
# ============================================================

normalizar_nombre <- function(x) {
  x |>
    tolower() |>
    trimws() |>
    iconv(to = "ASCII//TRANSLIT") |>
    gsub("[^a-z0-9 ]", "", x = _) |>
    gsub("\\s+", " ", x = _)
}


# ============================================================
# 1. Preparar tabla de metadatos de cada fuente
# ============================================================

# -- ROR --
tabla_ror <- ror_spain |>
  transmute(
    ror_id,
    nombre_ror     = nombre,
    wikidata_ror   = wikidata_id,   # ID Wikidata tal como lo reporta ROR
    isni_id        = isni_id,
    fundref_id     = fundref_id,
    ciudad_ror     = ciudad,
    tipo_ror       = tipo,
    website_ror    = website,
    nombre_norm    = normalizar_nombre(nombre)
  )

# -- GBIF publishers --
tabla_gbif <- gbiforg_spain |>
  select(gbif_publisher_key = publishingOrg, nombre_gbif = publisher_name) |>
  distinct() |>
  mutate(nombre_norm = normalizar_nombre(nombre_gbif))

# -- GrSciColl instituciones --
tabla_grscioll <- grscioll_spain$instituciones |>
  transmute(
    grscioll_institution_id,
    nombre_grscioll  = nombre,
    codigo_grscioll  = codigo,
    ciudad_grscioll  = ciudad,
    website_grscioll = website,
    nombre_norm      = normalizar_nombre(nombre)
  )

# -- Index Herbariorum --
tabla_ih <- indexherbariorum_spain |>
  transmute(
    ih_id,
    codigo_ih  = codigo_herbario,
    nombre_ih  = nombre,
    ciudad_ih  = ciudad,
    pais_ih    = pais,
    website_ih = website,
    nombre_norm = normalizar_nombre(nombre)
  )

# -- OBIS --
tabla_obis <- obis_spain |>
  select(obis_institute_id = instituteid, nombre_obis = institute_name) |>
  distinct() |>
  mutate(nombre_norm = normalizar_nombre(nombre_obis))

# -- Wikidata --
# Wikidata contiene referencias cruzadas a ROR, GBIF publisher y GrSciColl
tabla_wikidata <- wikidata_spain |>
  transmute(
    wikidata_id,
    nombre_wikidata         = nombre,
    ciudad_wikidata         = ciudad_nombre,
    website_wikidata        = website,
    ror_id_wd               = ror_id,
    isni_id_wd              = isni_id,
    gbif_publisher_key_wd   = gbif_publisher_key,
    grscioll_inst_id_wd     = grscioll_inst_id,
    nombre_norm             = normalizar_nombre(nombre)
  )


# ============================================================
# 2. Construir tabla semilla de pares de identificadores
# ============================================================
# Estrategia:
#   a) Partir de Wikidata como broker central (tiene referencias a otros registros)
#   b) Agregar entidades de ROR que no esten en Wikidata
#   c) Agregar entidades de GBIF, GrSciColl, IH, OBIS que no esten vinculadas

# a) Wikidata como ancla
semilla <- tabla_wikidata |>
  select(wikidata_id, ror_id_wd, gbif_publisher_key_wd,
         grscioll_inst_id_wd, nombre_norm, nombre_wikidata,
         ciudad_wikidata, website_wikidata, isni_id_wd)

# b) Unir ROR: via wikidata_ror (ID Wikidata que ROR conoce) o via nombre
semilla <- semilla |>
  full_join(
    tabla_ror |> select(ror_id, wikidata_ror, nombre_norm, nombre_ror,
                        isni_id, fundref_id, ciudad_ror, tipo_ror, website_ror),
    by = c("ror_id_wd" = "ror_id"),
    suffix = c("", "_ror")
  ) |>
  mutate(
    nombre_norm = coalesce(nombre_norm, nombre_norm_ror),
    ror_id      = ror_id_wd,
    wikidata_id = coalesce(wikidata_id, wikidata_ror),
    isni_id     = coalesce(isni_id_wd, isni_id)
  ) |>
  select(-nombre_norm_ror, -wikidata_ror, -ror_id_wd, -isni_id_wd)

# c) Unir GBIF publishers
semilla <- semilla |>
  left_join(
    tabla_gbif |> select(gbif_publisher_key, nombre_gbif, nombre_norm_gbif = nombre_norm),
    by = c("gbif_publisher_key_wd" = "gbif_publisher_key")
  ) |>
  rename(gbif_publisher_key = gbif_publisher_key_wd) |>
  mutate(nombre_norm = coalesce(nombre_norm, nombre_norm_gbif)) |>
  select(-nombre_norm_gbif)

# Agregar publishers de GBIF no vinculados via Wikidata
gbif_extra <- tabla_gbif |>
  filter(!gbif_publisher_key %in% semilla$gbif_publisher_key) |>
  left_join(
    semilla |> filter(!is.na(nombre_norm)) |>
      select(nombre_norm, ror_id, wikidata_id) |> distinct(),
    by = "nombre_norm"
  ) |>
  filter(is.na(ror_id) & is.na(wikidata_id)) |>
  transmute(
    wikidata_id = NA_character_, ror_id = NA_character_,
    gbif_publisher_key, nombre_gbif, grscioll_inst_id_wd = NA_character_,
    nombre_wikidata = NA_character_, ciudad_wikidata = NA_character_,
    website_wikidata = NA_character_, isni_id = NA_character_,
    fundref_id = NA_character_, nombre_ror = NA_character_,
    ciudad_ror = NA_character_, tipo_ror = NA_character_,
    website_ror = NA_character_, nombre_norm
  )

semilla <- bind_rows(semilla, gbif_extra)

# d) Unir GrSciColl
semilla <- semilla |>
  left_join(
    tabla_grscioll |> select(grscioll_institution_id, nombre_grscioll,
                              codigo_grscioll, ciudad_grscioll,
                              website_grscioll, nombre_norm_gsc = nombre_norm),
    by = c("grscioll_inst_id_wd" = "grscioll_institution_id")
  ) |>
  rename(grscioll_institution_id = grscioll_inst_id_wd) |>
  mutate(nombre_norm = coalesce(nombre_norm, nombre_norm_gsc)) |>
  select(-nombre_norm_gsc)

# Agregar instituciones GrSciColl no vinculadas
grscioll_extra <- tabla_grscioll |>
  filter(!grscioll_institution_id %in% semilla$grscioll_institution_id) |>
  left_join(
    semilla |> filter(!is.na(nombre_norm)) |>
      select(nombre_norm, ror_id, wikidata_id) |> distinct(),
    by = "nombre_norm"
  ) |>
  filter(is.na(ror_id) & is.na(wikidata_id)) |>
  transmute(
    wikidata_id = NA_character_, ror_id = NA_character_,
    gbif_publisher_key = NA_character_, nombre_gbif = NA_character_,
    grscioll_institution_id, nombre_grscioll, codigo_grscioll,
    ciudad_grscioll, website_grscioll,
    nombre_wikidata = NA_character_, ciudad_wikidata = NA_character_,
    website_wikidata = NA_character_, isni_id = NA_character_,
    fundref_id = NA_character_, nombre_ror = NA_character_,
    ciudad_ror = NA_character_, tipo_ror = NA_character_,
    website_ror = NA_character_, nombre_norm
  )

semilla <- bind_rows(semilla, grscioll_extra)

# e) Unir Index Herbariorum por nombre normalizado
semilla <- semilla |>
  left_join(
    tabla_ih |> select(ih_id, codigo_ih, nombre_ih, ciudad_ih,
                        pais_ih, website_ih, nombre_norm_ih = nombre_norm),
    by = c("nombre_norm" = "nombre_norm_ih")
  )

# Agregar herbarios no vinculados
ih_extra <- tabla_ih |>
  filter(!nombre_norm %in% semilla$nombre_norm) |>
  transmute(
    wikidata_id = NA_character_, ror_id = NA_character_,
    gbif_publisher_key = NA_character_, nombre_gbif = NA_character_,
    grscioll_institution_id = NA_character_,
    nombre_grscioll = NA_character_, codigo_grscioll = NA_character_,
    ciudad_grscioll = NA_character_, website_grscioll = NA_character_,
    nombre_wikidata = NA_character_, ciudad_wikidata = NA_character_,
    website_wikidata = NA_character_, isni_id = NA_character_,
    fundref_id = NA_character_, nombre_ror = NA_character_,
    ciudad_ror = NA_character_, tipo_ror = NA_character_,
    website_ror = NA_character_,
    ih_id, codigo_ih, nombre_ih, ciudad_ih, pais_ih, website_ih,
    nombre_norm
  )

semilla <- bind_rows(semilla, ih_extra)

# f) Unir OBIS por nombre normalizado
semilla <- semilla |>
  left_join(
    tabla_obis |> select(obis_institute_id, nombre_obis, nombre_norm_obis = nombre_norm),
    by = c("nombre_norm" = "nombre_norm_obis")
  )

# Agregar instituciones OBIS no vinculadas
obis_extra <- tabla_obis |>
  filter(!nombre_norm %in% semilla$nombre_norm) |>
  transmute(
    wikidata_id = NA_character_, ror_id = NA_character_,
    gbif_publisher_key = NA_character_, nombre_gbif = NA_character_,
    grscioll_institution_id = NA_character_,
    nombre_grscioll = NA_character_, codigo_grscioll = NA_character_,
    ciudad_grscioll = NA_character_, website_grscioll = NA_character_,
    nombre_wikidata = NA_character_, ciudad_wikidata = NA_character_,
    website_wikidata = NA_character_, isni_id = NA_character_,
    fundref_id = NA_character_, nombre_ror = NA_character_,
    ciudad_ror = NA_character_, tipo_ror = NA_character_,
    website_ror = NA_character_,
    ih_id = NA_character_, codigo_ih = NA_character_,
    nombre_ih = NA_character_, ciudad_ih = NA_character_,
    pais_ih = NA_character_, website_ih = NA_character_,
    obis_institute_id, nombre_obis,
    nombre_norm
  )

semilla <- bind_rows(semilla, obis_extra)


# ============================================================
# 3. Seleccion y ordenado de columnas finales
# ============================================================

tabla_equivalencia <- semilla |>
  transmute(
    # Nombre canonico de referencia
    nombre_canonico         = nombre_norm,
    # Identificadores globales
    ror_id,
    wikidata_id,
    isni_id,
    fundref_id,
    # GBIF.org (publisher)
    gbif_publisher_key,
    nombre_gbif,
    # GrSciColl
    grscioll_institution_id,
    nombre_grscioll,
    codigo_grscioll,
    # Index Herbariorum
    ih_id,
    codigo_ih,
    nombre_ih,
    # OBIS
    obis_institute_id,
    nombre_obis,
    # ROR (metadatos adicionales)
    nombre_ror,
    ciudad_ror,
    tipo_ror,
    website_ror,
    # Wikidata (metadatos adicionales)
    nombre_wikidata,
    ciudad_wikidata,
    website_wikidata
  ) |>
  arrange(nombre_canonico)


message(
  "Tabla de equivalencias construida: ",
  nrow(tabla_equivalencia), " entidades, ",
  sum(!is.na(tabla_equivalencia$ror_id)), " con ROR ID, ",
  sum(!is.na(tabla_equivalencia$wikidata_id)), " con Wikidata ID, ",
  sum(!is.na(tabla_equivalencia$gbif_publisher_key)), " con GBIF publisher, ",
  sum(!is.na(tabla_equivalencia$grscioll_institution_id)), " con GrSciColl, ",
  sum(!is.na(tabla_equivalencia$ih_id)), " con Index Herbariorum, ",
  sum(!is.na(tabla_equivalencia$obis_institute_id)), " con OBIS."
)
