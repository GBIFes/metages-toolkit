# Database Exploration Script
# This script performs comprehensive exploration of the GBIF Spain Collections Registry database

# Load required modules
source("src/connection/db_connection.R")
source("src/exploration/data_exploration.R")

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Default parameters
environment <- if (length(args) >= 1) args[1] else "TEST"
output_dir <- if (length(args) >= 2) args[2] else "output"
generate_report <- if (length(args) >= 3) as.logical(args[3]) else TRUE

# Validate environment parameter
if (!environment %in% c("PROD", "TEST")) {
  stop("Environment must be either 'PROD' or 'TEST'")
}

# Create output directory
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Main execution
main <- function() {
  cat("=== GBIF Spain Collections Registry - Database Exploration ===\n")
  cat(paste("Environment:", environment, "\n"))
  cat(paste("Output directory:", output_dir, "\n"))
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
    
    # Get connection information
    conn_info <- get_connection_info(conn)
    cat("Database Information:\n")
    cat(paste("- Server version:", conn_info$server_version, "\n"))
    cat(paste("- Current database:", conn_info$current_database, "\n"))
    cat(paste("- Connection valid:", conn_info$connection_valid, "\n\n"))
    
    # Explore database schema
    cat("Exploring database schema...\n")
    schema_info <- explore_database_schema(conn)
    
    if (!is.null(schema_info)) {
      cat(paste("✓ Found", schema_info$table_count, "tables\n"))
      cat(paste("✓ Database size:", schema_info$database_size_mb, "MB\n"))
      
      # Display table information
      cat("\nTable Statistics:\n")
      for (i in 1:nrow(schema_info$table_statistics)) {
        table_stat <- schema_info$table_statistics[i, ]
        cat(sprintf("- %s: %d rows, %d columns\n", 
                   table_stat$table_name, 
                   table_stat$row_count, 
                   table_stat$columns))
      }
      cat("\n")
    }
    
    # Explore individual tables
    tables <- dbListTables(conn)
    
    for (table in tables) {
      cat(paste("Exploring table:", table, "...\n"))
      
      # Table structure
      structure_info <- explore_table_structure(conn, table)
      if (!is.null(structure_info)) {
        cat(paste("✓", table, "- Structure analyzed\n"))
      }
      
      # Data summary
      summary_info <- get_data_summary(conn, table, sample_size = 1000)
      if (!is.null(summary_info)) {
        cat(paste("✓", table, "- Data summary generated\n"))
      }
      
      # Data quality assessment
      quality_info <- explore_data_quality(conn, table)
      if (!is.null(quality_info)) {
        cat(paste("✓", table, "- Quality assessment completed\n"))
        
        if (quality_info$empty_rows_percentage > 10) {
          cat(paste("⚠ Warning:", table, "has", quality_info$empty_rows_percentage, "% empty rows\n"))
        }
      }
    }
    
    # Generate comprehensive report
    if (generate_report) {
      cat("\nGenerating comprehensive exploration report...\n")
      
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      report_file <- file.path(output_dir, paste0("exploration_report_", environment, "_", timestamp))
      
      exploration_report <- generate_exploration_report(conn, report_file)
      
      if (!is.null(exploration_report)) {
        cat(paste("✓ Exploration report saved to:", report_file, "\n"))
        
        # Generate summary text file
        summary_file <- paste0(report_file, "_summary.txt")
        generate_exploration_summary(exploration_report, summary_file)
        cat(paste("✓ Summary report saved to:", summary_file, "\n"))
      }
    }
    
    # Close connection
    close_database_connection(conn)
    cat("\n✓ Database connection closed\n")
    
    cat("\n=== Exploration completed successfully ===\n")
    
  }, error = function(e) {
    cat(paste("✗ Error:", e$message, "\n"))
    
    # Close connection if it exists
    if (exists("conn") && !is.null(conn)) {
      close_database_connection(conn)
    }
    
    stop("Exploration failed")
  })
}

# Helper function to generate exploration summary
generate_exploration_summary <- function(report, output_file) {
  summary_lines <- c(
    "GBIF Collections Registry - Exploration Summary",
    paste("Generated:", report$timestamp),
    "",
    "Database Overview:",
    paste("- Tables:", length(report$table_explorations)),
    paste("- Total size:", report$schema_info$database_size_mb, "MB"),
    ""
  )
  
  # Add table summaries
  summary_lines <- c(summary_lines, "Table Details:")
  
  for (table_name in names(report$table_explorations)) {
    table_data <- report$table_explorations[[table_name]]
    
    if (!is.null(table_data$structure)) {
      summary_lines <- c(summary_lines, 
                         paste("-", table_name, ":", table_data$structure$row_count, "rows,", 
                               table_data$structure$column_count, "columns"))
    }
    
    if (!is.null(table_data$quality)) {
      if (table_data$quality$empty_rows_percentage > 10) {
        summary_lines <- c(summary_lines, 
                           paste("  ⚠ Warning:", table_data$quality$empty_rows_percentage, "% empty rows"))
      }
    }
  }
  
  writeLines(summary_lines, output_file)
}

# Usage information
if (length(args) == 0 || args[1] %in% c("-h", "--help")) {
  cat("GBIF Collections Registry - Database Exploration Script\n\n")
  cat("Usage: Rscript run_exploration.R [ENVIRONMENT] [OUTPUT_DIR] [GENERATE_REPORT]\n\n")
  cat("Parameters:\n")
  cat("  ENVIRONMENT     Database environment: 'PROD' or 'TEST' (default: 'TEST')\n")
  cat("  OUTPUT_DIR      Output directory for reports (default: 'output')\n")
  cat("  GENERATE_REPORT Generate comprehensive report: TRUE/FALSE (default: TRUE)\n\n")
  cat("Examples:\n")
  cat("  Rscript run_exploration.R TEST\n")
  cat("  Rscript run_exploration.R PROD output TRUE\n")
  cat("  Rscript run_exploration.R TEST reports FALSE\n\n")
  quit("no")
}

# Run main function
main()