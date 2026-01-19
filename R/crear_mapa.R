#' Crear mapa de colecciones METAGES
#'
#' Genera un mapa con puntos sobre un basemap, aplicando filtros opcionales y
#' un facet opcional. Devuelve tanto el `ggplot` como los datos filtrados.
#'
#' La funcion asume que los datos de entrada contienen coordenadas
#' geograficas y metricas asociadas a colecciones.
#'
#' @param data data.frame con las columnas necesarias para el mapa. Se  
#'   genera automaticamente con \code{extraer_colecciones_mapa()}
#' @param basemap Lista devuelta por \code{get_basemap_es()}.
#' @param legend_params Lista de parametros de leyenda. Si `NULL`, se calcula con
#'   \code{compute_legend_params(data)}.
#' @param tipo_coleccion 
#'  Uno de `coleccion`, `base de datos` o `NULL`.
#' @param disciplina 
#'  Uno de `Zool\u00F3gica`, `Bot\u00E1nica`, `Paleontol\u00F3gica`,
#'  `Mixta`, `Microbiol\u00F3gica`, `Micol\u00F3gica` o `NULL`.
#' @param subdisciplina 
#'  Uno de `Vertebrados`, `Invertebrados`, `Invertebrados y vertebrados`, `Plantas`, `Hongos`, `Algas` o `NULL`.
#' @param publican
#'  Uno de `TRUE`, `FALSE` o `NULL`.
#' @param facet Nombre de columna (string) para facetar o `NULL`.
#'
#' @return Invisiblemente, una lista con:
#' \describe{
#'   \item{plot}{Objeto `ggplot`.}
#'   \item{data_map}{data.frame con los datos tras filtros.}
#' }
#'
#' @import ggplot2
#' @import dplyr
#' @import sf
#' @import ggrepel
#'
#' @export

# Mapa
crear_mapa <- function(data = data,
                       basemap, 
                       legend_params = NULL,
                       tipo_coleccion = NULL, 
                       disciplina = NULL,     
                       subdisciplina = NULL,
                       publican = NULL,       
                       facet = NULL) {     
  
  
  # --------------------------------------------------
  # 0. Validacion de argumentos
  # --------------------------------------------------
  
  tipo_coleccion <- if (!is.null(tipo_coleccion)) {
    match.arg(tipo_coleccion, c("coleccion", "base de datos"))
  } else NULL
  
  disciplina <- if (!is.null(disciplina)) {
    match.arg(disciplina, c(
      "Zool\u00F3gica", "Bot\u00E1nica", "Paleontol\u00F3gica",
      "Mixta", "Microbiol\u00F3gica", "Micol\u00F3gica"
    )
    )
  } else NULL
  
  subdisciplina <- if (!is.null(subdisciplina)) {
    match.arg(subdisciplina, c(
      "Vertebrados", "Invertebrados",
      "Invertebrados y vertebrados",
      "Plantas", "Hongos", "Algas"
    ))
  } else NULL
  
  if (!is.null(publican) && (!is.logical(publican) || length(publican) != 1)) {
    stop("`publican` must be TRUE, FALSE or NULL", call. = FALSE)
  }
  
  if (!is.null(facet)) {
    if (!is.character(facet) || length(facet) != 1 || !facet %in% names(data)) {
      stop("`facet` must be a column name in `data` or NULL", call. = FALSE)
    }
  }
  
  
  # --------------------------------------------------
  # 1. Llamar parametros para la leyenda
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
    value_label <- "N\u00FAmero de registros"
  } else if (isTRUE(publican)) {
    value_var   <- "numberOfRecords"
    value_label <- "N\u00FAmero de registros"
  } else {
    value_var   <- "number_of_subunits"
    value_label <- "N\u00FAmero de ejemplares"
  }
  
  

  # --------------------------------------------------
  # 3. Filtrado
  # --------------------------------------------------
  # Deben ser secuenciales en el orden indicado ya que algunos dependen de otros
  # Los argumentos de la funcion definiran los filtros.
  # Una vez se ha seleccionado la variable activa, limpiamos los datos
  data_clean <- data %>% filter(.data[[value_var]] > 0)

  
  # Opcional: Filtra por tipo de coleccion
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
  # 4. Construccion del mapa
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
  
    
    # Titulo y subtitulo del grafico dinamicos
    labs(
      title = paste(
        "Distribuci\u00F3n de ",
        if (is.null(tipo_coleccion)) {"colecciones biol\u00F3gicas y bases de datos"
            } else if (tipo_coleccion == "coleccion") {"colecciones biol\u00F3gicas"
            } else if (tipo_coleccion == "base de datos") {"bases de datos"},
        " en GBIF Espa\u00F1a"
                    ),
      subtitle = paste(
        c(
          if (!is.null(disciplina)) paste0("Disciplina: ", disciplina) else NULL,
          if (!is.null(subdisciplina)) paste0("Subdisciplina: ", subdisciplina) else NULL,
          if (!is.null(publican)) paste0("Publican en GBIF: ", ifelse(publican, "S\u00ED", "No")) else NULL
        ),
        collapse = " \u00B7 "
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
    if (facet == "publica_en_gbif") {
      plot <- plot +
        facet_wrap(
          vars(.data[[facet]]),
          labeller = as_labeller(
            c(`0` = "No publica en GBIF", `1` = "Publica en GBIF")
          )
        )
    } else {
      plot <- plot +
        facet_wrap(vars(.data[[facet]]))
    }
  }
  
  
  message(
    "crear_mapa(): ",
    nrow(data_clean),
    " l\u00EDneas tras aplicar filtros"
  )
  
  return(invisible(list(
    plot = plot,
    data_map = data_clean)))
  
}

