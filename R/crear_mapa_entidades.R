#' Crear mapa de entidades en el Registro facetado segun publicacion en GBIF
#'
#' Genera un mapa del país que muestra la localizacion de las entidades
#' incluidas en el Registro de Colecciones de GBIF.ES. El mapa se facetiza segun el
#' estado de publicacion en GBIF (`publica_en_gbif`), separando visualmente
#' las entidades que publican de aquellas que no.
#'
#' Las entidades se representan mediante puntos fijos. Para evitar
#' ocultamientos completos entre entidades cercanas, se aplica un jitter
#' espacial muy leve. Los nombres que aparecen en el mapa corresponden a las
#' regiones, y se situan en el centroide empirico de las entidades de cada
#' region y panel, manteniendo coherencia cartografica.
#'
#'
#' @param tipo_coleccion Tipo de entidad a representar. Uno de
#'   \code{"coleccion"}, \code{"base de datos"} o \code{NULL}.
#'   Si es \code{NULL}, se muestran todas.
#'   
#'
#' @return Un objeto \code{ggplot}.
#'
#' @import ggplot2
#' @import dplyr
#' @import ggrepel
#'
#' @export
crear_mapa_entidades <- function(tipo_coleccion = NULL) {
  
  # --------------------------------------------------
  # 1. Carga de datos y basemap
  # --------------------------------------------------
  
  data <- extraer_colecciones_mapa()$data
  basemap <- get_basemap_es()
  
  
  # --------------------------------------------------
  # 1.1 Validacion de argumentos
  # --------------------------------------------------
  
  tipo_coleccion <- if (!is.null(tipo_coleccion)) {
    match.arg(tipo_coleccion, c("coleccion", "base de datos"))
  } else {
    NULL
  }
  
  
  # Filtrado opcional por tipo de coleccion
  if (!is.null(tipo_coleccion)) {
    data <- data %>%
      filter(tipo_body == tipo_coleccion)
  }
  
  
  
  # --------------------------------------------------
  # 2. Preparacion de datos de puntos (entidades)
  # --------------------------------------------------
  
  data_points <- data %>%
    filter(
      !is.na(longitude_adj),
      !is.na(latitude_adj),
      !is.na(publica_en_gbif),
      !is.na(region)
    ) %>%
    distinct(
      town,
      region,
      longitude_adj,
      latitude_adj,
      publica_en_gbif
    )
  
  # --------------------------------------------------
  # 3. Preparacion de datos de labels (centroides de region)
  # --------------------------------------------------
  
  data_labels <- data_points %>%
    group_by(region) %>%
    summarise(
      longitude_adj = mean(longitude_adj),
      latitude_adj  = mean(latitude_adj),
      .groups = "drop"
    )
  
  
  # --------------------------------------------------
  # 4. Colores (definidos internamente)
  # --------------------------------------------------
  
  colores_publicacion <- c(
    `0` = "#bdbdbd",  # No publica en GBIF
    `1` = "#1b9e77"   # Publica en GBIF
  )
  
  # --------------------------------------------------
  # 5. Construccion del mapa
  # --------------------------------------------------
  
  plot <- ggplot() +
    
    # Basemap
    geom_sf(
      data = basemap$vecinos,
      fill = "grey80",
      color = NA,
      alpha = 0.2
    ) +
    geom_sf(
      data = basemap$ES_fixed,
      fill = "grey",
      alpha = 0.3
    ) +
    
    # Cuadro de Canarias
    annotate(
      "rect",
      xmin = basemap$bb_can["xmin"] - 1,
      xmax = basemap$bb_can["xmax"] + 1,
      ymin = basemap$bb_can["ymin"] - 0.3,
      ymax = basemap$bb_can["ymax"] + 0.3,
      fill = NA,
      color = "grey70",
      linewidth = 0.3
    ) +
    
    # Puntos de entidades (jitter suave)
    geom_point(
      data = data_points,
      aes(
        x = longitude_adj,
        y = latitude_adj,
        color = factor(publica_en_gbif)
      ),
      size = 7,
      alpha = 0.7,
      position = position_jitter(
        width = 0.03,
        height = 0.02
      )
    ) +
    
    # Labels de regiones (sin jitter, centroides)
    geom_text_repel(
      data = data_labels,
      aes(
        x = longitude_adj,
        y = latitude_adj,
        label = region
      ),
      size = 3,
      max.overlaps = Inf,
      segment.color = NA
    ) +
    
    # Escala de color (sin leyenda: facet ya explica)
    scale_color_manual(
      name = "Publicaci\u00F3n en GBIF",
      values = colores_publicacion,
      labels = c(
        "No",
        "S\u00ED"
      )
    ) +
    
    # Zoom
    coord_sf(
      xlim = c(
        basemap$bb_fixed["xmin"] - 1,
        basemap$bb_fixed["xmax"] + 0.5
      ),
      ylim = c(
        basemap$bb_fixed["ymin"] - 0.5,
        basemap$bb_fixed["ymax"] + 0.5
      ),
      expand = FALSE
    ) +
    
    # Tema
    theme_void() +
    theme(
      strip.text = element_text(face = "bold", size = 10),
      panel.background = element_rect(fill = "#f5f5f2", color = NA),
      plot.background  = element_rect(fill = "#f5f5f2", color = NA),
      text = element_text(color = "#22211d"),
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold", color = "#4e4d47"),
      plot.subtitle = element_text(face = "bold", color = "#4e4d47"),
      legend.position = c(0.1, 0.6),
      legend.title = element_text(size = 9, face = "bold"),
      legend.text = element_text(size = 8)
    ) +
    
    labs(
      title = paste(
        "Localizaci\u00F3n de las",
        if (is.null(tipo_coleccion)) {"colecciones biol\u00F3gicas y bases de datos"
        } else if (tipo_coleccion == "coleccion") {"colecciones biol\u00F3gicas"
        } else if (tipo_coleccion == "base de datos") {"bases de datos"},
        " de GBIF Espa\u00F1a"
      )
    )
  
  message(
    "crear_mapa_entidades(): ",
    nrow(data_points),
    " entidades representadas"
  )
  
  return(plot)
}
