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
  )




crear_mapa <- function(data = data, 
                       disciplina = NULL, 
                       subdisciplina = NULL,
                       publican = NULL){
  
  # Preparar datos para filtros. Datos sin filtros
  data_clean <- data
  
  # Opcional: Filtra datos por disciplina
  if (!is.null(disciplina)) {
    data_clean <- data_clean %>% 
      filter(disciplina_def == disciplina)
  }
  
  # Opcional: Filtra datos por subdisciplina
  if (!is.null(subdisciplina)) {
    data_clean <- data_clean %>% 
      filter(disciplina_subtipo_def == subdisciplina)
  }
  
  # Opcional: Filtra datos por publicadores
  if (!is.null(publican)) {
    data_clean <- data_clean %>% 
      filter(publica_en_gbif == publican)   # cambia columna si es otra
  }
  
  
  # ---- VARIABLE ACTIVA ----
  if (isTRUE(publican)) {
    value_var   <- "numberOfRecords"
    value_label <- "Número de registros"
  } else {
    value_var   <- "number_of_subunits"
    value_label <- "Número de ejemplares"
  }
  
  
  
  # Quita duplicas para geom_ que lo necesiten
  data_clean_unique <- data_clean %>%
    select(town, disciplina_def, longitude_adj, latitude_adj) %>%
    distinct()
  
  
  # Calcular percentiles para leyenda. Calculamos los de number_of_subunits
  # independientemente de si se miden registros o ejemplares. 
  # Esto solo influye en el tamanho de la leyenda y permite que todas sean equiparables.
  # La transformacion raiz cuadrada mas adelante en scale_size_continuous ayudara a equiparar los valores.
  
  summary(data$number_of_subunits)
  
  mybreaks <- data %>%
    pull(number_of_subunits) %>%
    quantile(c(.1, .3, .5, .85), na.rm = TRUE) %>%
    (\(.) round(. / 100) * 100)() %>%
    as.character() %>%
    as.numeric()      
  
  
  limits <- range(data$number_of_subunits, na.rm = TRUE)
  
  
  
  
  # Build the map
  data_clean %>%
    ggplot() +
    geom_sf(data = vecinos, fill = "grey80", color = NA, alpha = 0.2) +
    geom_sf(data = ES_fixed, fill = "grey", alpha = 0.3) +
    
    # Cuadradito alrededor de canarias
    annotate(
      "rect",
      xmin = bb_can["xmin"] - 1, xmax = bb_can["xmax"] + 1,
      ymin = bb_can["ymin"] - 0.3, ymax = bb_can["ymax"] + 0.3,
      fill = NA,
      color = "grey70",
      linewidth = 0.3
    ) +
    
    # Burbujas
    geom_point(aes(x = longitude_adj, y = latitude_adj, 
                   size = .data[[value_var]], 
                   color = .data[[value_var]], 
                   alpha = .data[[value_var]]),
               shape = 20, stroke = FALSE
    ) +
    # Punto pequeño fijo por ciudad en cada facet
    geom_point(
      data = data_clean_unique,
      aes(x = longitude_adj, y = latitude_adj),
      size = 0.8,
      color = "black",
      alpha = 0.6
    ) +
    
    # Nombre de las ciudades
    geom_text_repel(
      data = data_clean_unique,
      aes(x = longitude_adj, y = latitude_adj, label = town), 
      alpha = 0.8,
      size = 3,
      max.overlaps = Inf,
      min.segment.length = 0,
      segment.alpha = 0.4
    ) +
    
    # Intervalos y transformacion de la leyenda para size
    scale_size_continuous(
      name = value_label, trans = "sqrt",
      range = c(5, 90), breaks = mybreaks, limits = limits
    ) +
    
    # Intervalos y transformacion de la leyenda para alpha
    scale_alpha_continuous(
      name = value_label, trans = "log",
      range = c(0.1, 0.4), breaks = mybreaks, limits = limits
    ) +
    
    # Intervalos y transformacion de la leyenda para color
    scale_color_viridis_c(
      option = "viridis", trans = "log",
      breaks = mybreaks, limits = limits, name = value_label
    ) +
    
    # Intervalos y transformacion de la leyenda para size
    # facet_wrap(~ disciplina_def) +
    
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
    
    # Titulo y subtitulo  del grafico
    labs(
      title = "Distribución de colecciones biológicas",
      subtitle = paste(
        c(
          if (!is.null(disciplina)) paste0("Disciplina: ", disciplina) else NULL,
          if (!is.null(subdisciplina)) paste0("Subdisciplina: ", subdisciplina) else NULL,
          if (!is.null(publican)) paste0("Publican en GBIF: ", ifelse(publican, "Sí", "No")) else NULL
        ),
        collapse = " · "
      )
    ) +
    
    
    # Otros cambios en el tema
    theme(
      strip.text = element_text(face = "bold", size = 10),
      panel.background = element_rect(fill = "#f5f5f2", color = NA),
      text = element_text(color = "#22211d"),
      plot.margin = margin(r = 2, l = 2, unit = "cm"),
      plot.background = element_rect(fill = "#f5f5f2", color = NA),
      plot.title = element_text(size = 14, hjust = 0.5, face= "bold", color = "#4e4d47"),
      plot.subtitle = element_text(face = "bold", color = "#4e4d47"),
      legend.position = c(0.08, 0.7),
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      # legend.background = element_rect(fill = "#f5f5f2",
      #                                  color = "grey70",
      #                                  linewidth = 0.3),
      # legend.margin = margin(6, 6, 0, 6)
    )
  
}


crear_mapa(data, disciplina = "Zoológica")
crear_mapa(data, disciplina = "Zoológica", subdisciplina = "Vertebrados")
crear_mapa(data, disciplina = "Zoológica", subdisciplina = "Invertebrados")
crear_mapa(data, disciplina = "Zoológica", subdisciplina = "Invertebrados y vertebrados")
crear_mapa(data, disciplina = "Botánica")
crear_mapa(data, disciplina = "Botánica", subdisciplina = "Plantas")
crear_mapa(data, disciplina = "Botánica", subdisciplina = "Algas")
crear_mapa(data, disciplina = "Botánica", subdisciplina = "Hongos")
crear_mapa(data, disciplina = "Paleontológica")
crear_mapa(data, disciplina = "Micológica")
crear_mapa(data, disciplina = "Mixta")
crear_mapa(data, disciplina = "Microbiológica")

crear_mapa(data, disciplina = "Zoológica", publican = T)
crear_mapa(data, disciplina = "Zoológica", subdisciplina = "Vertebrados", publican = T)
crear_mapa(data, disciplina = "Zoológica", subdisciplina = "Invertebrados", publican = T)
crear_mapa(data, disciplina = "Zoológica", subdisciplina = "Invertebrados y vertebrados", publican = T)
crear_mapa(data, disciplina = "Botánica", publican = T)
crear_mapa(data, disciplina = "Botánica", subdisciplina = "Plantas", publican = T)
crear_mapa(data, disciplina = "Botánica", subdisciplina = "Algas", publican = T)
crear_mapa(data, disciplina = "Botánica", subdisciplina = "Hongos", publican = T)
crear_mapa(data, disciplina = "Paleontológica", publican = T)
crear_mapa(data, disciplina = "Micológica", publican = T)
crear_mapa(data, disciplina = "Mixta", publican = T)
crear_mapa(data, disciplina = "Microbiológica", publican = T)

crear_mapa(data, disciplina = "Micológica", publican = F)
crear_mapa(data, disciplina = "Mixta", publican = F)
crear_mapa(data, disciplina = "Microbiológica", publican = F)

