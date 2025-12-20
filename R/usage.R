
# GENERAR INFORME
render_informe()



# TESTAR FUNCIONES

#library(metagesToolkit)

# 1. Extraer dominio
res <- extraer_colecciones_mapa()
data <- res$data

# 2. Basemap
basemap <- get_basemap_es()

# 3. Legend params (editables aquí)
legend <- compute_legend_params(
  data,
  probs = c(.1, .4, .65, .9)
)


# 4. Crear mapa

# Posibilidades para el Facet
names(extraer_colecciones_mapa()$data)

mapa <- crear_mapa(
  data = data,
  basemap = basemap,
  legend_params = legend,
  facet = "disciplina_def"
)

# Mostrar
mapa$plot

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------

# Del tiron
crear_mapa(
  data = extraer_colecciones_mapa()$data,
  basemap = get_basemap_es(),
  legend_params = compute_legend_params(extraer_colecciones_mapa()$data),
  facet = "publica_en_gbif"
)$plot




#---------------------------------------------------------------------------
#---------------------------------------------------------------------------


# Quick tests
names(data)
crear_mapa(data = data, basemap = basemap, legend_params = legend, publican= T, facet = "tipo_body")$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend, facet = "software_gestion_col")$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend, facet = "publica_en_gbif")$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend,
           tipo_coleccion = "base de datos",
           disciplina = "Botánica",
           subdisciplina = "Plantas")$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend,
           tipo_coleccion = "base de datos")$plot


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------


################## Mapas posibles ##################

# Valores permitidos
tipos <- c(NA, "colección", "base de datos")
publican_vals <- c(NA, TRUE, FALSE)

disciplinas <- c(
  NA,
  "Zoológica",
  "Botánica",
  "Paleontológica",
  "Mixta",
  "Microbiológica",
  "Micológica"
)

sub_map <- list(
  "Zoológica" = c(NA, "Vertebrados", "Invertebrados", "Invertebrados y vertebrados"),
  "Botánica"  = c(NA, "Plantas", "Hongos", "Algas")
)

# Lista de expresiones
calls_expr <- list()

for (tc in tipos) {
  for (d in disciplinas) {
    
    # Subdisciplinas válidas según disciplina
    sub_opts <- if (is.na(d)) { NA
    } else if (d %in% names(sub_map)) { sub_map[[d]]
    } else { NA }
    
    for (sd in sub_opts) {
      for (p in publican_vals) {
        
        args <- list(data = quote(data))
        
        if (!is.na(tc)) args$tipo_coleccion <- tc
        if (!is.na(d))  args$disciplina     <- d
        if (!is.na(sd)) args$subdisciplina  <- sd
        if (!is.na(p))  args$publican       <- p
        
        calls_expr[[length(calls_expr) + 1]] <-
          as.call(c(quote(crear_mapa), args))
      }}}}


# Llamadas validas
cat(paste0(sprintf("%03d: ",
                   seq_along(calls_expr)),
           vapply(calls_expr,
                  function(x) paste(deparse(x), 
                                    collapse = ""),
                  character(1))),
    sep = "\n")




# TESTING
# Llamada basandose en indice
eval(calls_expr[[001]])
eval(calls_expr[[102]])
eval(calls_expr[[79]])

# Llamadas basandose en funcion
crear_mapa(data = data, basemap = basemap, legend_params = legend, tipo_coleccion = "base de datos", disciplina = "Botánica", subdisciplina = "Plantas", publican = TRUE)$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend, tipo_coleccion = "colección", disciplina = "Zoológica")$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend, tipo_coleccion = "base de datos")$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend, tipo_coleccion = "colección", disciplina = "Zoológica",     publican = F)$plot
crear_mapa(data = data, basemap = basemap, legend_params = legend)$plot




