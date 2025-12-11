# ==== TOP 10 PAISES CON MÁS REGISTROS EN GBIF ====
# Opción A: rgbif (recomendada)

# Instalar y cargar paquetes packages
pkgs <- c("rgbif", "dplyr", "ggplot2", "scales", "countrycode", "tibble")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}


# Top N countries in number of records in GBIF
get_top10_countries_rgbif <- function() {
  df <- occ_count_country() |>
    arrange(desc(count)) |>
    slice_head(n = 10) |>                    # seleccionar numero de paises a extraer
    mutate(pais = countrycode(iso2, "iso2c", # traducir paises a espanol
                              "cldr.name.es", 
                              custom_dict = codelist)) |>
    select(pais, iso2, count)
  df
}

top_countries <- get_top10_countries_rgbif()



#----------------------------------------------------
#PUBLISHING COUNTRY

# Top N publishing countries (publishers' country), using facets
get_top_publishing_countries <- function(n = 10, facet_limit = 300) {
  res <- rgbif::occ_search(
    facet = "publishingCountry",
    limit = 0,                 # no occurrence rows, just facets
    facetLimit = facet_limit,   # raise if you need more
    occurrenceStatus = NULL    # Outputs both presences and absences
  )
  res$facets$publishingCountry |>
    dplyr::transmute(
      publishingCountry = name,                  # ISO2 of publisher's country
      count = as.double(count),
      pais_publicador = countrycode::countrycode(
        publishingCountry, "iso2c", "cldr.name.es")
    ) |>
    dplyr::arrange(dplyr::desc(count)) |>
    dplyr::slice_head(n = n)
}

top_publishers <- get_top_publishing_countries(15)
top_publishers



#----------------------------------------------------

# -------- NUEVO: ranking ACUMULADO hasta fin de año anterior --------
prev_year <- as.integer(format(Sys.Date(), "%Y")) - 1L

res_prev_cum <- occ_search(
  facet = "country",
  year  = sprintf("*,%d", prev_year),   # <= prev_year (acumulado histórico)
  limit = 0,
  facetLimit = 30
)

prev_cum <- as_tibble(res_prev_cum$facets$country$counts) |>
  transmute(country = name, count_prev_cum = as.double(count)) |>
  arrange(desc(count_prev_cum)) |>
  mutate(posicion_prev_cum = dplyr::row_number()) |>
  select(country, posicion_prev_cum, count_prev_cum)

# Unir la posición acumulada previa al top-10 actual
top_countries <- top_countries |>
  left_join(prev_cum, by = "country")

# -------- Traducción al español y selección de columnas --------
data("codelist", package = "countrycode")

top_countries <- top_countries |>
  mutate(
    pais = countrycode(country, "iso2c", "cldr.name.es", custom_dict = codelist)
  ) |>
  select(pais, country, count, posicion_prev_cum, count_prev_cum) |>
  arrange(desc(count))

print(top_countries)




# 4) Plot (barras horizontales)
ggplot(top_countries, aes(x = reorder(pais, count), y = count)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 10 países por número de registros en GBIF",
    subtitle = "Fuente: GBIF.org (via paquete rgbif)",
    x = NULL, y = "Número de registros"
  ) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  theme_minimal(base_size = 12)


