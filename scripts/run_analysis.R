# Script de Análisis de Datos
# Este script realiza análisis comprensivo de datos en la base de datos del Registro de Colecciones de GBIF

# Cargar módulos requeridos
source("src/connection/db_connection.R")
source("src/analysis/data_analysis.R")

# Analizar argumentos de línea de comandos
args <- commandArgs(trailingOnly = TRUE)

# Parámetros por defecto
environment <- if (length(args) >= 1) args[1] else "TEST"
output_dir <- if (length(args) >= 2) args[2] else "output"
analysis_types <- if (length(args) >= 3) strsplit(args[3], ",")[[1]] else c("all")
export_formats <- if (length(args) >= 4) strsplit(args[4], ",")[[1]] else c("rds", "csv")

# Validar parámetro de entorno
if (!environment %in% c("PROD", "TEST")) {
  stop("El entorno debe ser 'PROD' o 'TEST'")
}

# Validar tipos de análisis
valid_analysis_types <- c("all", "trends", "coverage", "patterns", "completeness", "dashboard")
invalid_types <- analysis_types[!analysis_types %in% valid_analysis_types]
if (length(invalid_types) > 0) {
  stop(paste("Tipos de análisis inválidos:", paste(invalid_types, collapse = ", ")))
}

# Crear directorio de salida
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Main execution
main <- function() {
  cat("=== GBIF Collections Registry - Data Analysis ===\n")
  cat(paste("Environment:", environment, "\n"))
  cat(paste("Output directory:", output_dir, "\n"))
  cat(paste("Analysis types:", paste(analysis_types, collapse = ", "), "\n"))
  cat(paste("Export formats:", paste(export_formats, collapse = ", "), "\n"))
  cat("\n")
  
  # Establish database connection
  cat("Connecting to database...\n")
  tryCatch({
    conn <- setup_database_connection(environment)
    cat("✓ Database connection established\n\n")
    
    # Test connection
    if (test_connection(conn)) {
      cat("✓ Database connection test passed\n\n")
    } else {
      stop("Database connection test failed")
    }
    
    # Initialize results
    analysis_results <- list()
    analysis_results$timestamp <- Sys.time()
    analysis_results$environment <- environment
    analysis_results$analysis_types_requested <- analysis_types
    
    # Run requested analyses
    if ("all" %in% analysis_types || "dashboard" %in% analysis_types) {
      cat("Generating comprehensive analytics dashboard...\n\n")
      
      dashboard_results <- generate_analytics_dashboard(conn)
      analysis_results <- dashboard_results
      
      # Display key metrics
      display_dashboard_summary(dashboard_results)
      
    } else {
      # Run specific analyses
      if ("trends" %in% analysis_types) {
        cat("Running collection trends analysis...\n")
        trends_results <- analyze_collection_trends(conn)
        analysis_results$collection_trends <- trends_results
        display_trends_summary(trends_results)
      }
      
      if ("coverage" %in% analysis_types) {
        cat("Running institutional coverage analysis...\n")
        coverage_results <- analyze_institutional_coverage(conn)
        analysis_results$institutional_coverage <- coverage_results
        display_coverage_summary(coverage_results)
      }
      
      if ("patterns" %in% analysis_types) {
        cat("Running data patterns analysis...\n")
        patterns_results <- analyze_data_patterns(conn)
        analysis_results$data_patterns <- patterns_results
        display_patterns_summary(patterns_results)
      }
      
      if ("completeness" %in% analysis_types) {
        cat("Running completeness trends analysis...\n")
        completeness_results <- analyze_completeness_trends(conn)
        analysis_results$completeness_trends <- completeness_results
        display_completeness_summary(completeness_results)
      }
    }
    
    # Export results
    cat("\nExporting analysis results...\n")
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_prefix <- paste0("analysis_", environment, "_", timestamp)
    
    export_analysis_results(analysis_results, output_prefix, export_formats)
    cat("✓ Analysis results exported successfully\n")
    
    # Generate visualizations if requested
    if ("rds" %in% export_formats || "all" %in% analysis_types || "dashboard" %in% analysis_types) {
      cat("\nGenerating visualizations...\n")
      generate_analysis_visualizations(analysis_results, output_dir, timestamp)
    }
    
    # Close connection
    close_database_connection(conn)
    cat("\n✓ Database connection closed\n")
    
    cat("\n=== Data analysis completed successfully ===\n")
    
  }, error = function(e) {
    cat(paste("✗ Error:", e$message, "\n"))
    
    # Close connection if it exists
    if (exists("conn") && !is.null(conn)) {
      close_database_connection(conn)
    }
    
    stop("Analysis failed")
  })
}

# Helper functions for displaying summaries
display_dashboard_summary <- function(dashboard) {
  cat("Dashboard Summary:\n")
  
  # KPIs
  if (!is.null(dashboard$kpis)) {
    cat("Key Performance Indicators:\n")
    if (!is.null(dashboard$kpis$total_institutions)) {
      cat(paste("- Total Institutions:", dashboard$kpis$total_institutions, "\n"))
    }
    if (!is.null(dashboard$kpis$total_collections)) {
      cat(paste("- Total Collections:", dashboard$kpis$total_collections, "\n"))
    }
    if (!is.null(dashboard$kpis$recent_collections_30_days)) {
      cat(paste("- Collections added (30 days):", dashboard$kpis$recent_collections_30_days, "\n"))
    }
  }
  
  # Health Score
  if (!is.null(dashboard$health_score)) {
    cat(paste("Data Health Score:", dashboard$health_score$overall_score, "- ", dashboard$health_score$rating, "\n"))
  }
  
  cat("\n")
}

display_trends_summary <- function(trends) {
  if (is.null(trends)) return()
  
  cat("Collection Trends Summary:\n")
  
  # Creation trends
  if (!is.null(trends$creation_trends) && nrow(trends$creation_trends) > 0) {
    recent_creations <- tail(trends$creation_trends, 3)
    cat("Recent creation activity:\n")
    for (i in 1:nrow(recent_creations)) {
      row <- recent_creations[i, ]
      cat(paste("- ", row$time_period, ": ", row$collections_created, " collections\n"))
    }
  }
  
  # Activity analysis
  if (!is.null(trends$activity_analysis) && nrow(trends$activity_analysis) > 0) {
    cat("Activity levels:\n")
    for (i in 1:nrow(trends$activity_analysis)) {
      row <- trends$activity_analysis[i, ]
      cat(paste("- ", row$activity_level, ": ", row$count, " collections\n"))
    }
  }
  
  cat("\n")
}

display_coverage_summary <- function(coverage) {
  if (is.null(coverage)) return()
  
  cat("Institutional Coverage Summary:\n")
  
  # Geographic coverage
  if (!is.null(coverage$geographic_coverage) && nrow(coverage$geographic_coverage) > 0) {
    top_countries <- head(coverage$geographic_coverage, 5)
    cat("Top countries by institution count:\n")
    for (i in 1:nrow(top_countries)) {
      row <- top_countries[i, ]
      cat(paste("- ", row$country, ": ", row$institution_count, " institutions, ", 
                row$collection_count, " collections\n"))
    }
  }
  
  # Size distribution
  if (!is.null(coverage$size_distribution) && nrow(coverage$size_distribution) > 0) {
    cat("Institution size distribution:\n")
    for (i in 1:nrow(coverage$size_distribution)) {
      row <- coverage$size_distribution[i, ]
      cat(paste("- ", row$size_category, ": ", row$institution_count, " institutions\n"))
    }
  }
  
  cat("\n")
}

display_patterns_summary <- function(patterns) {
  if (is.null(patterns)) return()
  
  cat("Data Patterns Summary:\n")
  
  # Entry patterns
  if (!is.null(patterns$entry_patterns) && !is.null(patterns$entry_patterns$day_of_week_patterns)) {
    dow_patterns <- patterns$entry_patterns$day_of_week_patterns
    if (nrow(dow_patterns) > 0) {
      busiest_day <- dow_patterns[which.max(dow_patterns$entries_count), ]
      cat(paste("Busiest entry day:", busiest_day$day_of_week, "with", busiest_day$entries_count, "entries\n"))
    }
  }
  
  cat("\n")
}

display_completeness_summary <- function(completeness) {
  if (is.null(completeness)) return()
  
  cat("Completeness Trends Summary:\n")
  
  # Display overall completeness for each table
  for (table_name in names(completeness)) {
    if (grepl("_overall$", table_name)) {
      table_data <- completeness[[table_name]]
      clean_name <- gsub("_overall$", "", table_name)
      cat(paste("Table:", clean_name, "\n"))
      
      # Find columns with lowest completeness
      if (ncol(table_data) > 0) {
        completeness_cols <- names(table_data)[grepl("_completeness$", names(table_data))]
        if (length(completeness_cols) > 0) {
          completeness_values <- as.numeric(table_data[1, completeness_cols])
          names(completeness_values) <- gsub("_completeness$", "", completeness_cols)
          
          min_completeness <- min(completeness_values, na.rm = TRUE)
          min_field <- names(completeness_values)[which.min(completeness_values)]
          
          cat(paste("- Lowest completeness:", min_field, "at", min_completeness, "%\n"))
        }
      }
    }
  }
  
  cat("\n")
}

generate_analysis_visualizations <- function(analysis_results, output_dir, timestamp) {
  # Generate basic visualizations (placeholder - would implement actual plots)
  cat("Generating visualizations...\n")
  
  tryCatch({
    # Create plots directory
    plots_dir <- file.path(output_dir, "plots")
    if (!dir.exists(plots_dir)) {
      dir.create(plots_dir, recursive = TRUE)
    }
    
    # Placeholder for actual visualization generation
    # This would create ggplot2 charts, save as PNG/PDF files
    
    # Create a simple summary visualization text file
    viz_summary_file <- file.path(plots_dir, paste0("visualization_summary_", timestamp, ".txt"))
    
    viz_summary <- c(
      "GBIF Collections Registry - Analysis Visualizations",
      paste("Generated:", Sys.time()),
      "",
      "Visualization files would be generated here:",
      "- Collection trends over time (line chart)",
      "- Geographic distribution (world map)",
      "- Institution size distribution (bar chart)",
      "- Completeness trends (heatmap)",
      "- Data quality dashboard (combined charts)",
      "",
      "Note: Actual visualization generation requires additional",
      "implementation based on specific charting requirements."
    )
    
    writeLines(viz_summary, viz_summary_file)
    cat(paste("✓ Visualization summary saved to:", viz_summary_file, "\n"))
    
  }, error = function(e) {
    cat(paste("⚠ Warning: Could not generate visualizations:", e$message, "\n"))
  })
}

# Usage information
if (length(args) == 0 || args[1] %in% c("-h", "--help")) {
  cat("GBIF Collections Registry - Data Analysis Script\n\n")
  cat("Usage: Rscript run_analysis.R [ENVIRONMENT] [OUTPUT_DIR] [ANALYSIS_TYPES] [EXPORT_FORMATS]\n\n")
  cat("Parameters:\n")
  cat("  ENVIRONMENT     Database environment: 'PROD' or 'TEST' (default: 'TEST')\n")
  cat("  OUTPUT_DIR      Output directory for results (default: 'output')\n")
  cat("  ANALYSIS_TYPES  Comma-separated list of analysis types (default: 'all')\n")
  cat("                  Options: 'all', 'trends', 'coverage', 'patterns', 'completeness', 'dashboard'\n")
  cat("  EXPORT_FORMATS  Comma-separated list of export formats (default: 'rds,csv')\n")
  cat("                  Options: 'rds', 'csv', 'json'\n\n")
  cat("Examples:\n")
  cat("  Rscript run_analysis.R TEST\n")
  cat("  Rscript run_analysis.R PROD output dashboard rds,csv\n")
  cat("  Rscript run_analysis.R TEST results trends,coverage csv\n\n")
  quit("no")
}

# Run main function
main()