# build_site.R

# Actualizar Analisis estructural de metagesToolkit
source("inst/scripts/actualizar_pkgnet_arquitectura.R")

# 1. Reconstruir la web normal de pkgdown
pkgdown::clean_site()
pkgdown::build_site()

# 2. Crea carpeta limpia para WordPress
dir.create("docs/embed/dashboard-metricas", recursive = TRUE, showWarnings = FALSE)

# 3. Renderiza una versión limpia del dashboard
rmarkdown::render(
  input = "vignettes/dashboard-metricas.Rmd",
  output_file = "index.html",
  output_dir = "docs/embed/dashboard-metricas",
  quiet = FALSE
)
