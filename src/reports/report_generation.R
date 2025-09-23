# Módulo de Generación de Reportes para Registro de Colecciones GBIF España
# LENGUAJE: R
# Este módulo genera reportes similares al Informe de Colecciones GBIF España

# Cargar librerías requeridas
library(DBI)
library(dplyr)
library(ggplot2)
library(knitr)
library(rmarkdown)

#' Generar Reporte de Colecciones GBIF España
#' 
#' Genera un reporte completo sobre el estado de las colecciones registradas
#' 
#' @param connection Conexión a base de datos
#' @param output_dir Directorio de salida para el reporte
#' @param year Año del reporte (default: año actual)
#' @param format Formato de salida ("html", "pdf", "word")
#' @return Ruta al archivo de reporte generado
#' @export
generate_collections_report <- function(connection, output_dir = "output", 
                                       year = format(Sys.Date(), "%Y"), 
                                       format = "html") {
  
  loginfo("Iniciando generación de reporte de colecciones GBIF España")
  
  # Crear directorio de salida si no existe
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Recopilar datos para el reporte
  report_data <- collect_report_data(connection, year)
  
  # Generar visualizaciones
  charts <- generate_report_charts(report_data)
  
  # Crear archivo de reporte
  report_file <- create_report_document(report_data, charts, output_dir, year, format)
  
  loginfo(paste("Reporte generado exitosamente:", report_file))
  return(report_file)
}

#' Recopilar Datos para el Reporte
#' 
#' @param connection Conexión a base de datos
#' @param year Año del reporte
#' @return Lista con datos estructurados para el reporte
collect_report_data <- function(connection, year) {
  
  data <- list()
  data$year <- year
  data$generation_date <- Sys.Date()
  
  # Estadísticas generales del registro
  data$general_stats <- get_general_statistics(connection)
  
  # Distribución por tipos de colecciones
  data$collection_types <- get_collection_types_distribution(connection)
  
  # Distribución geográfica
  data$geographic_distribution <- get_geographic_distribution(connection)
  
  return(data)
}

#' Obtener Estadísticas Generales
#' 
#' @param connection Conexión a base de datos
#' @return Lista con estadísticas generales
get_general_statistics <- function(connection) {
  
  stats <- list()
  
  # Total de colecciones registradas
  stats$total_collections <- execute_safe_query(connection, 
    "SELECT COUNT(*) as count FROM metages_accesocol")$count
  
  # Total de instituciones
  stats$total_institutions <- execute_safe_query(connection, 
    "SELECT COUNT(DISTINCT nombre_institucion) as count FROM metages_accesocol WHERE nombre_institucion IS NOT NULL")$count
  
  return(stats)
}