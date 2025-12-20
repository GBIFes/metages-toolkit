# Instalar y cargar paquetes packages
pkgs <- c("ggplot2", "dplyr", "giscoR", "dplyr", "sf", "ggrepel")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}


# Mapa
crear_mapa <- function(data = data,
                       basemap, 
                       legend_params = NULL,
                       tipo_coleccion = NULL, # "colección" | "base de datos" | NULL
                       disciplina = NULL,     
                       subdisciplina = NULL,
                       publican = NULL,       # TRUE | FALSE | NULL
                       facet = NULL) {     
  
  
  # --------------------------------------------------
  # 1. Legend params (globales, sobre el dominio)
  # --------------------------------------------------
  if (is.null(legend_params)) {
    legend_params <- compute_legend_params(data)
  }
  
  
  
  # --------------------------------------------------
  # 2. Variable activa
  # --------------------------------------------------
  # Creacion de una variable activa para usar unos valores u otros en 
  # funcion de los argumentos de crear_mapa()
  if (identical(tipo_coleccion, "base de datos")) {
    value_var   <- "numberOfRecords"
    value_label <- "Número de registros"
  } else if (isTRUE(publican)) {
    value_var   <- "numberOfRecords"
    value_label <- "Número de registros"
  } else {
    value_var   <- "number_of_subunits"
    value_label <- "Número de ejemplares"
  }
  
  

  # --------------------------------------------------
  # 3. Filtrado
  # --------------------------------------------------
  # Deben ser secuenciales en el orden indicado ya que algunos dependen de otros
  # Los argumentos de la funcion definiran los filtros.
  # Una vez se ha seleccionado la variable activa, limpiamos los datos
  data_clean <- data %>% filter(.data[[value_var]] > 0)

  
  # Opcional: Filtra por tipo de colección
  if (!is.null(tipo_coleccion)) {
    data_clean <- data_clean %>%
      filter(tipo_body == tipo_coleccion)
  }
  
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
      filter(publica_en_gbif == publican)
  }
  
  # Opcional: Eliminar NA en la variable de facetado
  if (!is.null(facet)) {
    data_clean <- data_clean %>%
      filter(!is.na(.data[[facet]]))
  }

  
  
  # Quita duplicas para los geom_ que lo necesiten
  if (is.null(facet)) {
    data_labels <- data_clean %>%
      select(town, longitude_adj, latitude_adj) %>%
      distinct()
  } else {
    data_labels <- data_clean %>%
      select(
        town,
        longitude_adj,
        latitude_adj,
        !!sym(facet)
      ) %>%
      distinct()
  }
  

  
  # --------------------------------------------------
  # 4. Construcción del mapa
  # --------------------------------------------------
  
  plot <- data_clean %>%
    ggplot() +
    geom_sf(data = basemap$vecinos, fill = "grey80", color = NA, alpha = 0.2) +
    geom_sf(data = basemap$ES_fixed, fill = "grey", alpha = 0.3) +
    
    # Cuadradito alrededor de canarias
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
    
    # Burbujas
    geom_point(aes(x = longitude_adj, y = latitude_adj, 
                   size = .data[[value_var]], 
                   color = .data[[value_var]], 
                   alpha = .data[[value_var]]),
               shape = 20, 
               stroke = FALSE
    ) +
    # Puntito fijo por ciudad
    geom_point(
      data = data_labels,
      aes(x = longitude_adj, y = latitude_adj),
      size = 0.8,
      color = "black",
      alpha = 0.6
    ) +
    
    # Nombre de las ciudades
    geom_text_repel(
      data = data_labels,
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
      range = c(5, 70), breaks = legend_params$mybreaks, limits = legend_params$limits,
      labels = function(x) format(x, scientific = FALSE)
    ) +
    
    # Intervalos y transformacion de la leyenda para alpha
    scale_alpha_continuous(
      name = value_label, trans = "log",
      range = c(0.1, 0.4), breaks = legend_params$mybreaks, limits = legend_params$limits,
      labels = function(x) format(x, scientific = FALSE)
    ) +
    
    # Intervalos y transformacion de la leyenda para color
    scale_color_viridis_c(
      option = "viridis", trans = "log",
      breaks = legend_params$mybreaks, limits = legend_params$limits, name = value_label,
      labels = function(x) format(x, scientific = FALSE)
    ) +
    
    # Zoom del mapa
    coord_sf(
      xlim = c(basemap$bb_fixed["xmin"] - 1, 
               basemap$bb_fixed["xmax"] + 0.5),
      ylim = c(basemap$bb_fixed["ymin"] - 0.5, 
               basemap$bb_fixed["ymax"] + 0.5),
      expand = FALSE
    ) +
    
    # Tema general del grafico
    theme_void() +
    
    # Fuerza scale_color_viridis_c a usar guide_legend().
    # Permitiendo que las leyendas se unan en una sola
    guides(colour = guide_legend()) +
  
    
    # Titulo y subtitulo del grafico dinámicos
    labs(
      title = paste(
        "Distribución de ",
        if (is.null(tipo_coleccion)) {"colecciones biológicas y bases de datos"
            } else if (tipo_coleccion == "colección") {"colecciones biológicas"
            } else if (tipo_coleccion == "base de datos") {"bases de datos"},
        " en GBIF España"
                    ),
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
      #legend.position = c(0.08, 0.7),
      legend.position = c(0.02, 0.6),
      legend.title = element_text(size = 9, face = "bold"),
      legend.text = element_text(size = 8)
    )
  
  # ---------------- Facet opcional ----------------
  if (!is.null(facet)) {
    plot <- plot +
      facet_wrap(vars(.data[[facet]]))
  }
  
  
  message(
    "crear_mapa(): ",
    nrow(data_clean),
    " líneas tras aplicar filtros"
  )
  
  return(invisible(list(
    plot = plot,
    data_map = data_clean)))
  
}

