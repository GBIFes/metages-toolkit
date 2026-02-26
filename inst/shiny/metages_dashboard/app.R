# ============================================================
# METAGES Dashboard
# Dashboard interactivo para explorar las métricas, tablas
# e imágenes del Registro de Colecciones de GBIF España.
# ============================================================

library(shiny)
library(dplyr)
library(ggplot2)
library(metagesToolkit)

# ---- Rutas a datos incluidos en el paquete -----------------
data_path  <- system.file("reports/data", package = "metagesToolkit")
mapas_path <- file.path(data_path, "mapas")
sql_path   <- file.path(data_path, "vistas_sql")

# ---- Carga de datos principales ----------------------------
colbd <- readRDS(file.path(mapas_path, "mapa-total.rds"))

# ---- Opciones de filtros -----------------------------------
disciplinas   <- c("Todas" = "",
                   sort(unique(na.omit(colbd$disciplina_def))))
subdisciplinas_all <- sort(unique(na.omit(colbd$disciplina_subtipo_def)))
tipos         <- c("Todas" = "", "coleccion", "base de datos")

# Helper: convierte "" a NULL para los filtros de las funciones del paquete
nullify <- function(x) if (is.null(x) || !nzchar(x)) NULL else x

# Paleta de colores interna del paquete
pal_categoria <- metagesToolkit:::pal_categoria

# ============================================================
# UI
# ============================================================
ui <- navbarPage(
  title = "METAGES Dashboard",

  # ---- Tab: Resumen ----------------------------------------
  tabPanel(
    "Resumen",
    fluidRow(
      column(
        12,
        h3("Métricas principales del Registro METAGES"),
        p("Los datos corresponden a la última actualización incluida en el paquete.")
      )
    ),
    fluidRow(
      column(3,
        wellPanel(
          h4(textOutput("n_total"),    style = "text-align:center; font-size:2em;"),
          p("Colecciones y bases de datos", style = "text-align:center;")
        )
      ),
      column(3,
        wellPanel(
          h4(textOutput("n_entidades"), style = "text-align:center; font-size:2em;"),
          p("Entidades",                style = "text-align:center;")
        )
      ),
      column(3,
        wellPanel(
          h4(textOutput("n_pub"),       style = "text-align:center; font-size:2em;"),
          p("Publican en GBIF",         style = "text-align:center;")
        )
      ),
      column(3,
        wellPanel(
          h4(textOutput("n_registros"), style = "text-align:center; font-size:2em;"),
          p("Registros totales en GBIF", style = "text-align:center;")
        )
      )
    ),
    fluidRow(
      column(6,
        h4("Distribución por disciplina"),
        plotOutput("resumen_disciplina", height = "320px")
      ),
      column(6,
        h4("Distribución por tipo"),
        plotOutput("resumen_tipo", height = "320px")
      )
    )
  ),

  # ---- Tab: Mapa -------------------------------------------
  tabPanel(
    "Mapa",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Filtros"),
        selectInput("mapa_tipo",         "Tipo de recurso", choices = tipos),
        selectInput("mapa_disciplina",   "Disciplina",      choices = disciplinas),
        uiOutput("mapa_subdisciplina_ui"),
        selectInput("mapa_publican",     "Publica en GBIF",
                    choices = c("Todos" = "", "Sí" = "TRUE", "No" = "FALSE")),
        selectInput("mapa_facet",        "Facetar por",
                    choices = c("Ninguno" = "",
                                "Disciplina" = "disciplina_def",
                                "Tipo de recurso" = "tipo_body",
                                "Publica en GBIF" = "publica_en_gbif")),
        hr(),
        p(em("El mapa base se descarga la primera vez que se carga esta pestaña."))
      ),
      mainPanel(
        width = 9,
        plotOutput("mapa_plot", height = "600px")
      )
    )
  ),

  # ---- Tab: Gráficos ---------------------------------------
  tabPanel(
    "Gráficos",
    tabsetPanel(
      # Evolución temporal
      tabPanel(
        "Evolución temporal",
        br(),
        plotOutput("barplot_anno", height = "450px")
      ),
      # Publicación en GBIF
      tabPanel(
        "Publicación en GBIF",
        br(),
        radioButtons(
          "nivel_pub", "Nivel de agregación:",
          choices  = c("Colecciones y bases de datos" = "colecciones",
                       "Entidades"                    = "entidades"),
          inline   = TRUE
        ),
        plotOutput("barplot_pub", height = "450px")
      ),
      # Distribución por disciplina (pie chart)
      tabPanel(
        "Por disciplina",
        br(),
        radioButtons(
          "pie_tipo", "Tipo de recurso:",
          choices = c("Colecciones" = "col",
                      "Bases de datos" = "bd",
                      "Todos" = "todos"),
          inline  = TRUE
        ),
        radioButtons(
          "pie_variable", "Variable:",
          choices = c("Disciplina" = "disciplina_def",
                      "Subdisciplina" = "disciplina_subtipo_def"),
          inline  = TRUE
        ),
        plotOutput("piechart_disciplina", height = "500px")
      ),
      # Top colecciones
      tabPanel(
        "Top colecciones",
        br(),
        plotOutput("barplot_top", height = "450px")
      )
    )
  ),

  # ---- Tab: Tablas -----------------------------------------
  tabPanel(
    "Tablas",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        h4("Filtros"),
        selectInput("tbl_tipo",        "Tipo de recurso", choices = tipos),
        selectInput("tbl_disciplina",  "Disciplina",      choices = disciplinas),
        uiOutput("tbl_subdisciplina_ui"),
        selectInput("tbl_publican",    "Publica en GBIF",
                    choices = c("Todos" = "", "Sí" = "1", "No" = "0")),
        downloadButton("tbl_download", "Descargar CSV")
      ),
      mainPanel(
        width = 9,
        DT::dataTableOutput("tabla_colbd")
      )
    )
  )
)

# ============================================================
# SERVER
# ============================================================
server <- function(input, output, session) {

  # ---- Basemap (carga única y en caché) --------------------
  basemap <- reactive({
    withProgress(message = "Descargando mapa base (solo la primera vez)…",
                 value = 0.5, {
      tryCatch(
        get_basemap_es(),
        error = function(e) {
          showNotification(
            paste("No se pudo cargar el mapa base:", conditionMessage(e)),
            type = "error", duration = 10
          )
          NULL
        }
      )
    })
  }) |> bindCache("basemap_es")

  # ---- UI dinámico: subdisciplina según disciplina (mapa) --
  output$mapa_subdisciplina_ui <- renderUI({
    disc <- input$mapa_disciplina
    if (!nzchar(disc)) {
      subs <- subdisciplinas_all
    } else {
      subs <- colbd |>
        filter(disciplina_def == disc) |>
        pull(disciplina_subtipo_def) |>
        na.omit() |>
        unique() |>
        sort()
    }
    selectInput("mapa_subdisciplina", "Subdisciplina",
                choices = c("Todas" = "", subs))
  })

  # ---- UI dinámico: subdisciplina según disciplina (tabla) -
  output$tbl_subdisciplina_ui <- renderUI({
    disc <- input$tbl_disciplina
    if (!nzchar(disc)) {
      subs <- subdisciplinas_all
    } else {
      subs <- colbd |>
        filter(disciplina_def == disc) |>
        pull(disciplina_subtipo_def) |>
        na.omit() |>
        unique() |>
        sort()
    }
    selectInput("tbl_subdisciplina", "Subdisciplina",
                choices = c("Todas" = "", subs))
  })

  # ---- Resumen: métricas -----------------------------------
  output$n_total     <- renderText(nrow(colbd))
  output$n_entidades <- renderText(
    colbd |> distinct(institucion_proyecto) |> nrow()
  )
  output$n_pub       <- renderText(
    colbd |> filter(publica_en_gbif == 1) |> nrow()
  )
  output$n_registros <- renderText(
    scales::number(
      sum(colbd$numberOfRecords, na.rm = TRUE),
      big.mark = ".", decimal.mark = ","
    )
  )

  output$resumen_disciplina <- renderPlot({
    colbd |>
      filter(!is.na(disciplina_def)) |>
      count(disciplina_def) |>
      ggplot(aes(
        x = n,
        y = forcats::fct_reorder(disciplina_def, n),
        fill = disciplina_def
      )) +
      geom_col(alpha = 0.8, width = 0.6) +
      geom_text(aes(label = n), hjust = -0.1, size = 4) +
      scale_fill_manual(values = pal_categoria, guide = "none") +
      scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
      labs(x = "N.º colecciones y bases de datos", y = NULL) +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 12))
  })

  output$resumen_tipo <- renderPlot({
    colbd |>
      filter(!is.na(tipo_body)) |>
      count(tipo_body) |>
      ggplot(aes(
        x = n,
        y = forcats::fct_reorder(tipo_body, n),
        fill = tipo_body
      )) +
      geom_col(alpha = 0.8, width = 0.5) +
      geom_text(aes(label = n), hjust = -0.1, size = 4) +
      scale_fill_manual(
        values = c("coleccion" = "#3B6AA0", "base de datos" = "#2ECC9A"),
        guide  = "none"
      ) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
      labs(x = "N.º recursos", y = NULL) +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 12))
  })

  # ---- Mapa ------------------------------------------------
  output$mapa_plot <- renderPlot({
    bm <- basemap()
    req(!is.null(bm))

    lp <- compute_legend_params(colbd)

    tipo   <- nullify(input$mapa_tipo)
    disc   <- nullify(input$mapa_disciplina)
    subdisc <- nullify(input$mapa_subdisciplina)
    pub    <- switch(
      input$mapa_publican,
      "TRUE"  = TRUE,
      "FALSE" = FALSE,
      NULL
    )
    facet  <- nullify(input$mapa_facet)

    result <- tryCatch(
      crear_mapa(
        data           = colbd,
        basemap        = bm,
        legend_params  = lp,
        tipo_coleccion = tipo,
        disciplina     = disc,
        subdisciplina  = subdisc,
        publican       = pub,
        facet          = facet
      ),
      error = function(e) {
        showNotification(paste("Error al generar el mapa:", conditionMessage(e)),
                         type = "error")
        NULL
      }
    )
    req(!is.null(result))
    result$plot
  })

  # ---- Gráfico: evolución temporal -------------------------
  output$barplot_anno <- renderPlot({
    crear_barplot_colecciones_por_anno(rdspath = sql_path)
  })

  # ---- Gráfico: publicación en GBIF -----------------------
  output$barplot_pub <- renderPlot({
    crear_barplot_publicacion(rdspath = sql_path, nivel = input$nivel_pub)
  })

  # ---- Gráfico: pie chart por disciplina ------------------
  output$piechart_disciplina <- renderPlot({

    # Preparar datos desde colbd de forma reactiva
    df_pie <- colbd
    if (input$pie_tipo == "col") {
      df_pie <- filter(df_pie, tipo_body == "coleccion")
    } else if (input$pie_tipo == "bd") {
      df_pie <- filter(df_pie, tipo_body == "base de datos")
    }

    var_cat <- input$pie_variable

    # Excluir NA en la variable elegida
    df_pie <- df_pie |>
      filter(!is.na(.data[[var_cat]])) |>
      count(.data[[var_cat]], name = "n") |>
      rename(categoria = 1)

    titulo <- switch(
      input$pie_tipo,
      "col"  = "Colecciones por disciplina",
      "bd"   = "Bases de datos por disciplina",
      "todos" = "Colecciones y bases de datos por disciplina"
    )

    # Reordenamiento intercalado (grande/pequeño) para legibilidad
    idx_desc <- order(df_pie$n, decreasing = TRUE)
    i <- 1L; j <- length(idx_desc); idx <- integer(0)
    while (i <= j) {
      idx <- c(idx, idx_desc[i]); i <- i + 1L
      if (i <= j) { idx <- c(idx, idx_desc[j]); j <- j - 1L }
    }
    df_pie <- df_pie[idx, , drop = FALSE]
    df_pie$categoria <- factor(df_pie$categoria, levels = df_pie$categoria)

    df_pie <- df_pie |>
      mutate(
        pct_raw  = n / sum(n) * 100,
        porcentaje = if_else(round(pct_raw) == 0,
                             round(pct_raw, 1),
                             round(pct_raw)),
        etiqueta = paste0(porcentaje, "%")
      )

    ggplot(df_pie, aes(x = "", y = n, fill = categoria)) +
      geom_col(width = 1, color = "grey70", linewidth = 0.6,
               show.legend = FALSE, alpha = 0.8) +
      geom_point(aes(x = NA_real_, y = NA_real_, fill = categoria),
                 inherit.aes = FALSE, shape = 21, size = 5,
                 show.legend = TRUE, na.rm = TRUE) +
      coord_polar(theta = "y", clip = "off") +
      geom_text(aes(label = etiqueta),
                position = position_stack(vjust = 0.5),
                size = 4, fontface = "bold", color = "white") +
      scale_fill_manual(values = pal_categoria, drop = FALSE) +
      guides(fill = guide_legend(
        override.aes = list(shape = 21, alpha = 0.8,
                            size = 10, colour = "grey70")
      )) +
      labs(title = titulo) +
      theme_minimal() +
      theme(
        axis.title = element_blank(),
        axis.text  = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank(),
        legend.title = element_blank(),
        plot.background  = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        legend.text  = element_text(size = 14),
        plot.title.position = "plot",
        plot.title = element_text(hjust = 0.5, size = 17,
                                  face = "bold", color = "#4e4d47")
      )
  })

  # ---- Gráfico: top colecciones ----------------------------
  output$barplot_top <- renderPlot({
    rds_path_mapa <- file.path(mapas_path, "mapa-total.rds")
    crear_barplot_top_colecciones_pub(rds_path = rds_path_mapa)
  })

  # ---- Tabla -----------------------------------------------
  tabla_filtrada <- reactive({
    d <- colbd
    tipo  <- input$tbl_tipo
    disc  <- input$tbl_disciplina
    subdisc <- input$tbl_subdisciplina
    pub   <- input$tbl_publican

    if (nzchar(tipo))    d <- filter(d, tipo_body == tipo)
    if (nzchar(disc))    d <- filter(d, disciplina_def == disc)
    if (!is.null(subdisc) && nzchar(subdisc))
      d <- filter(d, disciplina_subtipo_def == subdisc)
    if (nzchar(pub))     d <- filter(d, publica_en_gbif == as.integer(pub))

    d |>
      transmute(
        Institución    = institucion_proyecto,
        `Colección / BD` = coleccion_base,
        Código         = collection_code,
        Tipo           = tipo_body,
        Disciplina     = disciplina_def,
        Subdisciplina  = disciplina_subtipo_def,
        Localidad      = as.character(town),
        Provincia      = as.character(region),
        Ejemplares     = if_else(
          is.na(number_of_subunits) | number_of_subunits == 0, "-",
          scales::number(number_of_subunits,
                         big.mark = ".", decimal.mark = ",")
        ),
        `Registros GBIF` = if_else(
          is.na(numberOfRecords), "-",
          scales::number(numberOfRecords,
                         big.mark = ".", decimal.mark = ",")
        ),
        `Publica en GBIF` = if_else(publica_en_gbif == 1, "Sí", "No")
      ) |>
      distinct()
  })

  output$tabla_colbd <- DT::renderDataTable(
    tabla_filtrada(),
    filter   = "top",
    rownames = FALSE,
    options  = list(
      pageLength = 15,
      scrollX    = TRUE,
      language   = list(
        url = "//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json"
      )
    )
  )

  output$tbl_download <- downloadHandler(
    filename = function() {
      paste0("metages_colecciones_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(tabla_filtrada(), file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
}

# ============================================================
shinyApp(ui, server)
