library(sf)

# Datos mínimos para crear_mapa()
test_data <- data.frame(
  town = c("Madrid", "Madrid", "Sevilla"),
  region = c("Comunidad de Madrid", "Comunidad de Madrid", "Andalucía"),
  longitude = c("-3.7", "-3.7", "-3.5"),
  latitude  = c("40.4", "40.4", "39.0"),
  longitude_adj = c(-3.7, -3.7, -5.9),
  latitude_adj  = c(40.4, 40.4, 37.4),
  numberOfRecords = c(10, 0, 5),
  number_of_subunits = c(100, 50, 20),
  tipo_body = c("coleccion", "coleccion", "base de datos"),
  disciplina_def = c("Zoológica", "Zoológica", "Botánica"),
  disciplina_subtipo_def = c("Vertebrados", "Vertebrados", "Plantas"),
  publica_en_gbif = c(TRUE, FALSE, TRUE),
  facet_var = c("A", "A", NA),
  stringsAsFactors = FALSE
)

# Basemap mínimo (sf)
dummy_sf <- st_as_sf(
  data.frame(x = 1, y = 1),
  coords = c("x", "y"),
  crs = 4326
)

test_basemap <- list(
  vecinos = dummy_sf,
  ES_fixed = dummy_sf,
  bb_can = c(xmin = -18, xmax = -13, ymin = 27, ymax = 29),
  bb_fixed = c(xmin = -10, xmax = 5, ymin = 35, ymax = 45)
)

test_legend_params <- list(
  mybreaks = c(1, 10, 100),
  limits = c(1, 100)
)
