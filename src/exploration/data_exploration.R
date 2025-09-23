# Módulo de Exploración de Datos para el Registro de Colecciones de GBIF España
# Este módulo proporciona funciones comprensivas para explorar y perfilar el contenido de la base de datos

# Cargar librerías requeridas
library(DBI)
library(dplyr)
library(ggplot2)
library(knitr)
library(logging)

#' Explorar Esquema de Base de Datos
#' 
#' Proporciona una visión general de la estructura de la base de datos incluyendo tablas, vistas y relaciones
#' 
#' @param connection Objeto de conexión a base de datos
#' @return Lista con información del esquema
#' @export
explorar_esquema_base_datos <- function(connection) {
  loginfo("Iniciando exploración de esquema de base de datos")
  
  tryCatch({
    # Obtener lista de tablas
    tablas <- dbListTables(connection)
    
    info_esquema <- list()
    info_esquema$tablas <- tablas
    info_esquema$total_tablas <- length(tablas)
    
    # Obtener tamaños de tabla y conteos de filas
    estadisticas_tabla <- data.frame(
      nombre_tabla = character(),
      conteo_filas = numeric(),
      columnas = numeric(),
      stringsAsFactors = FALSE
    )
    
    for (tabla in tablas) {
      # Obtener conteo de filas
      consulta_conteo_filas <- paste("SELECT COUNT(*) as count FROM", tabla)
      conteo_filas <- execute_safe_query(connection, consulta_conteo_filas)$count
      
      # Obtener conteo de columnas
      columnas <- dbListFields(connection, tabla)
      conteo_col <- length(columnas)
      
      estadisticas_tabla <- rbind(estadisticas_tabla, data.frame(
        nombre_tabla = tabla,
        conteo_filas = conteo_filas,
        columnas = conteo_col,
        stringsAsFactors = FALSE
      ))
    }
    
    schema_info$table_statistics <- table_stats
    
    # Get database size information
    db_size_query <- "
      SELECT 
        table_schema as database_name,
        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as size_mb
      FROM information_schema.tables 
      WHERE table_schema = DATABASE()
      GROUP BY table_schema"
    
    db_size <- execute_safe_query(connection, db_size_query)
    schema_info$database_size_mb <- db_size$size_mb
    
    loginfo("Database schema exploration completed")
    return(schema_info)
    
  }, error = function(e) {
    logerror(paste("Error exploring database schema:", e$message))
    return(NULL)
  })
}

#' Explore Table Structure
#' 
#' Provides detailed information about a specific table structure
#' 
#' @param connection Database connection object
#' @param table_name Character. Name of the table to explore
#' @return List with table structure information
#' @export
explore_table_structure <- function(connection, table_name) {
  loginfo(paste("Exploring structure of table:", table_name))
  
  tryCatch({
    # Get column information
    columns_query <- paste("DESCRIBE", table_name)
    column_info <- execute_safe_query(connection, columns_query)
    
    # Get table information from information_schema
    table_info_query <- "
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default,
        column_key,
        extra
      FROM information_schema.columns 
      WHERE table_schema = DATABASE() 
      AND table_name = ?"
    
    detailed_info <- execute_safe_query(connection, table_info_query, list(table_name))
    
    # Get indices information
    indices_query <- paste("SHOW INDEX FROM", table_name)
    indices_info <- execute_safe_query(connection, indices_query)
    
    # Get row count
    row_count_query <- paste("SELECT COUNT(*) as count FROM", table_name)
    row_count <- execute_safe_query(connection, row_count_query)$count
    
    structure_info <- list(
      table_name = table_name,
      row_count = row_count,
      column_count = nrow(column_info),
      columns = column_info,
      detailed_columns = detailed_info,
      indices = indices_info
    )
    
    loginfo(paste("Table structure exploration completed for:", table_name))
    return(structure_info)
    
  }, error = function(e) {
    logerror(paste("Error exploring table structure:", e$message))
    return(NULL)
  })
}

#' Get Data Summary
#' 
#' Generates summary statistics for a table
#' 
#' @param connection Database connection object
#' @param table_name Character. Name of the table to summarize
#' @param sample_size Numeric. Number of rows to sample for analysis (default: 1000)
#' @return List with summary statistics
#' @export
get_data_summary <- function(connection, table_name, sample_size = 1000) {
  loginfo(paste("Generating data summary for table:", table_name))
  
  tryCatch({
    # Get sample data
    sample_query <- paste("SELECT * FROM", table_name, "LIMIT", sample_size)
    sample_data <- execute_safe_query(connection, sample_query)
    
    if (is.null(sample_data) || nrow(sample_data) == 0) {
      logwarn(paste("No data found in table:", table_name))
      return(NULL)
    }
    
    summary_info <- list()
    summary_info$table_name <- table_name
    summary_info$sample_size <- nrow(sample_data)
    
    # Basic statistics for each column
    column_summaries <- list()
    
    for (col_name in names(sample_data)) {
      col_data <- sample_data[[col_name]]
      
      col_summary <- list(
        column_name = col_name,
        data_type = class(col_data)[1],
        null_count = sum(is.na(col_data)),
        null_percentage = round(sum(is.na(col_data)) / length(col_data) * 100, 2),
        unique_count = length(unique(col_data[!is.na(col_data)]))
      )
      
      # Type-specific statistics
      if (is.numeric(col_data)) {
        col_summary$min <- min(col_data, na.rm = TRUE)
        col_summary$max <- max(col_data, na.rm = TRUE)
        col_summary$mean <- round(mean(col_data, na.rm = TRUE), 2)
        col_summary$median <- median(col_data, na.rm = TRUE)
        col_summary$std_dev <- round(sd(col_data, na.rm = TRUE), 2)
      } else if (is.character(col_data)) {
        col_summary$min_length <- min(nchar(col_data), na.rm = TRUE)
        col_summary$max_length <- max(nchar(col_data), na.rm = TRUE)
        col_summary$avg_length <- round(mean(nchar(col_data), na.rm = TRUE), 2)
        col_summary$empty_strings <- sum(col_data == "", na.rm = TRUE)
      }
      
      column_summaries[[col_name]] <- col_summary
    }
    
    summary_info$column_summaries <- column_summaries
    
    loginfo(paste("Data summary completed for table:", table_name))
    return(summary_info)
    
  }, error = function(e) {
    logerror(paste("Error generating data summary:", e$message))
    return(NULL)
  })
}

#' Explore Data Quality
#' 
#' Performs basic data quality assessment
#' 
#' @param connection Database connection object
#' @param table_name Character. Name of the table to assess
#' @return List with data quality metrics
#' @export
explore_data_quality <- function(connection, table_name) {
  loginfo(paste("Performing data quality assessment for table:", table_name))
  
  tryCatch({
    quality_metrics <- list()
    quality_metrics$table_name <- table_name
    
    # Get total row count
    total_rows_query <- paste("SELECT COUNT(*) as total FROM", table_name)
    total_rows <- execute_safe_query(connection, total_rows_query)$total
    quality_metrics$total_rows <- total_rows
    
    # Check for completely empty rows
    columns <- dbListFields(connection, table_name)
    non_null_condition <- paste(columns, "IS NOT NULL", collapse = " OR ")
    non_empty_query <- paste("SELECT COUNT(*) as non_empty FROM", table_name, "WHERE", non_null_condition)
    non_empty_rows <- execute_safe_query(connection, non_empty_query)$non_empty
    
    quality_metrics$empty_rows <- total_rows - non_empty_rows
    quality_metrics$empty_rows_percentage <- round((total_rows - non_empty_rows) / total_rows * 100, 2)
    
    # Check for duplicate rows (if reasonable table size)
    if (total_rows < 10000) {
      distinct_query <- paste("SELECT COUNT(DISTINCT *) as distinct_count FROM", table_name)
      distinct_rows <- execute_safe_query(connection, distinct_query)$distinct_count
      quality_metrics$duplicate_rows <- total_rows - distinct_rows
      quality_metrics$duplicate_percentage <- round((total_rows - distinct_rows) / total_rows * 100, 2)
    }
    
    # Column-specific quality checks
    column_quality <- list()
    for (col in columns) {
      null_query <- paste("SELECT COUNT(*) as null_count FROM", table_name, "WHERE", col, "IS NULL")
      null_count <- execute_safe_query(connection, null_query)$null_count
      
      col_quality <- list(
        column_name = col,
        null_count = null_count,
        null_percentage = round(null_count / total_rows * 100, 2),
        completeness = round((total_rows - null_count) / total_rows * 100, 2)
      )
      
      column_quality[[col]] <- col_quality
    }
    
    quality_metrics$column_quality <- column_quality
    
    loginfo(paste("Data quality assessment completed for table:", table_name))
    return(quality_metrics)
    
  }, error = function(e) {
    logerror(paste("Error in data quality assessment:", e$message))
    return(NULL)
  })
}

#' Generate Exploration Report
#' 
#' Creates a comprehensive exploration report for the database
#' 
#' @param connection Database connection object
#' @param output_file Character. Path to save the report (optional)
#' @return List with complete exploration results
#' @export
generate_exploration_report <- function(connection, output_file = NULL) {
  loginfo("Generating comprehensive exploration report")
  
  tryCatch({
    report <- list()
    report$timestamp <- Sys.time()
    report$connection_info <- get_connection_info(connection)
    
    # Database-level exploration
    report$schema_info <- explore_database_schema(connection)
    
    # Table-level exploration
    tables <- dbListTables(connection)
    report$table_explorations <- list()
    
    for (table in tables) {
      loginfo(paste("Processing table:", table))
      
      table_report <- list()
      table_report$structure <- explore_table_structure(connection, table)
      table_report$summary <- get_data_summary(connection, table)
      table_report$quality <- explore_data_quality(connection, table)
      
      report$table_explorations[[table]] <- table_report
    }
    
    # Save report if output file specified
    if (!is.null(output_file)) {
      saveRDS(report, output_file)
      loginfo(paste("Exploration report saved to:", output_file))
    }
    
    loginfo("Comprehensive exploration report completed")
    return(report)
    
  }, error = function(e) {
    logerror(paste("Error generating exploration report:", e$message))
    return(NULL)
  })
}