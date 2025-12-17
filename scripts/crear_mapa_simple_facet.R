# Instalar y cargar paquetes packages
pkgs <- c("ggplot2", "dplyr", "giscoR", "dplyr", "sf", "ggrepel")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}

# Descarga basemap

vecinos <- gisco_get_countries(country = c("PT", "FR", "AD", "MA", "DZ"),
                               resolution = 1)

ES <- gisco_get_countries(country = "ES", resolution = 1)


ES_main <- ES %>% 
  st_crop(xmin = -10, xmax = 5, ymin = 35, ymax = 44)  # península y baleares

ES_canary <- ES %>%
  st_crop(xmin = -19, xmax = -10, ymin = 27, ymax = 33)  # Canarias

# Desplazar Canarias hacia el noreste
ES_canary_shifted <- ES_canary %>% 
  mutate(geometry = geometry + c(5, 6)) %>%   # (desplaza X, desplaza Y)
  st_set_crs(st_crs(ES))

# Crear basemap final y definir bounding boxes
ES_fixed <- rbind(ES_main, ES_canary_shifted)

bb_fixed <- st_bbox(ES_fixed)
bb_can <- st_bbox(ES_canary_shifted)

#Conectar R a Metages con conectar_metages.R
# Extraer datos de metages
colecciones <- dbGetQuery(con, "SELECT *
                        FROM colecciones c")

# Limpiar tabla y anhadir geometria
data <- colecciones %>%
              mutate(across(where(is.character),
                            ~ na_if(trimws(.), ""))) %>%
              filter(number_of_subunits > 0,
                     !is.na(town),
                     tipo_body == 'colección') %>%
              arrange(number_of_subunits) %>%
              mutate(town = factor(town, unique(town)),
                     latitude = as.numeric(latitude),
                     longitude = as.numeric(longitude),
                     # el desplazamiento de longitude_adj y latitude_adj debe coincidir con el de ES_canary_shifted
                     longitude_adj = if_else(longitude < -10 & latitude < 34, longitude + 5, longitude), 
                     latitude_adj  = if_else(longitude < -10 & latitude < 34, latitude + 6, latitude)
                     ) # %>%
              # st_as_sf(coords = c("longitude", "latitude"), 
              #          crs = 4326,
              #          )


# Calcular percentiles para leyenda
summary(data$number_of_subunits)

mybreaks <- data %>%
  pull(number_of_subunits) %>%
  quantile(c(.1, .3, .5, .85), na.rm = TRUE) %>%
  (\(.) round(. / 100) * 100)() %>%
  as.character() %>%
  as.numeric()


# Create breaks for the color scale
# mybreaks2 <- c(258.2, 2000.0, 7500.0, 28879.6, 207041.6)


crear_mapa <- function(data = data){

# Build the map
data %>%
  ggplot() +
  geom_sf(data = vecinos, fill = "grey80", color = NA, alpha = 0.2) +
  geom_sf(data = ES_fixed, fill = "grey", alpha = 0.3) +

  # Cuadradito alrededor de canarias
  annotate(
    "rect",
    xmin = bb_can["xmin"] - 1, xmax = bb_can["xmax"] + 1,
    ymin = bb_can["ymin"] - 0.5, ymax = bb_can["ymax"] + 0.5,
    fill = NA,
    color = "grey70",
    linewidth = 0.3
  ) +

  # Burbujas
  geom_point(aes(x = longitude_adj, y = latitude_adj, 
                 size = number_of_subunits, 
                 color = number_of_subunits, 
                 alpha = number_of_subunits),
             shape = 20, stroke = FALSE
  ) +
  # Punto pequeño fijo por ciudad en cada facet
  geom_point(
    data = data %>%
      select(town, disciplina_def, longitude_adj, latitude_adj) %>%
      distinct(),
    aes(x = longitude_adj, y = latitude_adj),
    size = 0.8,
    color = "black",
    alpha = 0.6
  ) +

  # Nombre de las ciudades
  
  # geom_text(
  #   data = data %>% select (town, 
  #                           latitude,
  #                           longitude) %>%
  #                   distinct(),
  #   aes(x = longitude, y = latitude, label = town),
  #   size = 2,
  #   vjust = -0.8         # mueve el texto hacia arriba
  # ) +
  geom_text_repel(
    data = data %>% select (town,
                            disciplina_def,
                            latitude_adj,
                            longitude_adj) %>%
                                           distinct(),
    aes(x = longitude_adj, y = latitude_adj, label = town), 
    alpha = 0.8,
    size = 3,
    max.overlaps = Inf,
    min.segment.length = 0,
    segment.alpha = 0.4
  )+

  # Intervalos y transformacion de la leyenda para size
  scale_size_continuous(
    name = "Numero de ejemplares", trans = "sqrt",
    range = c(1, 55), breaks = mybreaks
  ) +
  
  # Intervalos y transformacion de la leyenda para alpha
  scale_alpha_continuous(
    name = "Numero de ejemplares", trans = "log",
    range = c(0.1, 0.4), breaks = mybreaks
  ) +
  
  # Intervalos y transformacion de la leyenda para color
  scale_color_viridis_c(
    option = "viridis", trans = "log",
    breaks = mybreaks, name = "Numero de ejemplares"
  ) +
  
  # Intervalos y transformacion de la leyenda para size
  facet_wrap(~ disciplina_def) +
  
  # Zoom del mapa
  coord_sf(
    xlim = c(bb_fixed["xmin"] - 1, bb_fixed["xmax"] + 0.5),
    ylim = c(bb_fixed["ymin"] - 0.5, bb_fixed["ymax"] + 0.5),
    expand = FALSE
  ) +

  # Tema general del grafico
  theme_void() +
  
  # Une las leyendas en una
  guides(colour = guide_legend()) +
  
  # Titulo del grafico
  ggtitle("Distribucion de colecciones biológicas") +
  
  # Otros cambios en el tema
  theme(
    strip.text = element_text(face = "bold", size = 10),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    text = element_text(color = "#22211d"),
    plot.margin = margin(r = 2, l = 2, unit = "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(size = 14, hjust = 0.5, color = "#4e4d47"),
    legend.position = c(1, 0.6),
    legend.title = element_text(size = 8),
    legend.text = element_text(size = 8)
  )

}


crear_mapa(data)
