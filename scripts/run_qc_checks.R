# Quality Control Checks Script
# This script performs comprehensive quality control checks on the GBIF Collections Registry database

# Load required modules
source("src/connection/db_connection.R")
source("src/quality_control/qc_checks.R")

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Default parameters
environment <- if (length(args) >= 1) args[1] else "TEST"
output_dir <- if (length(args) >= 2) args[2] else "output"
check_types <- if (length(args) >= 3) strsplit(args[3], ",")[[1]] else c("all")
generate_report <- if (length(args) >= 4) as.logical(args[4]) else TRUE

# Validate environment parameter
if (!environment %in% c("PROD", "TEST")) {
  stop("Environment must be either 'PROD' or 'TEST'")
}

# Validate check types
valid_check_types <- c("all", "completeness", "consistency", "validity", "business_rules")
invalid_types <- check_types[!check_types %in% valid_check_types]
if (length(invalid_types) > 0) {
  stop(paste("Invalid check types:", paste(invalid_types, collapse = ", ")))
}

# Create output directory
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Main execution
main <- function() {
  cat("=== GBIF Collections Registry - Quality Control Checks ===\n")
  cat(paste("Environment:", environment, "\n"))
  cat(paste("Output directory:", output_dir, "\n"))
  cat(paste("Check types:", paste(check_types, collapse = ", "), "\n"))
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
    qc_results <- list()
    qc_results$timestamp <- Sys.time()
    qc_results$environment <- environment
    qc_results$check_types_requested <- check_types
    
    # Run requested checks
    if ("all" %in% check_types) {
      cat("Running all quality control checks...\n\n")
      
      # Run comprehensive checks
      all_results <- run_all_qc_checks(conn)
      qc_results <- all_results
      
      # Display overall status
      cat(paste("Overall QC Status:", qc_results$overall_status, "\n\n"))
      
      # Display individual check statuses
      display_check_status("Completeness", qc_results$completeness$overall_status)
      display_check_status("Consistency", qc_results$consistency$overall_status)
      display_check_status("Validity", qc_results$validity$overall_status)
      display_check_status("Business Rules", qc_results$business_rules$overall_status)
      
    } else {
      # Run specific checks
      if ("completeness" %in% check_types) {
        cat("Running completeness checks...\n")
        completeness_results <- run_completeness_checks(conn)
        qc_results$completeness <- completeness_results
        display_check_status("Completeness", completeness_results$overall_status)
      }
      
      if ("consistency" %in% check_types) {
        cat("Running consistency checks...\n")
        consistency_results <- run_consistency_checks(conn)
        qc_results$consistency <- consistency_results
        display_check_status("Consistency", consistency_results$overall_status)
      }
      
      if ("validity" %in% check_types) {
        cat("Running validity checks...\n")
        validity_results <- run_validity_checks(conn)
        qc_results$validity <- validity_results
        display_check_status("Validity", validity_results$overall_status)
      }
      
      if ("business_rules" %in% check_types) {
        cat("Running business rules checks...\n")
        business_results <- run_business_rule_checks(conn)
        qc_results$business_rules <- business_results
        display_check_status("Business Rules", business_results$overall_status)
      }
    }
    
    # Display detailed results for failed checks
    cat("\n")
    display_detailed_results(qc_results)
    
    # Generate report if requested
    if (generate_report) {
      cat("\nGenerating QC report...\n")
      
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      report_file <- file.path(output_dir, paste0("qc_report_", environment, "_", timestamp))
      
      # Save comprehensive report
      saveRDS(qc_results, paste0(report_file, ".rds"))
      cat(paste("✓ Detailed QC report saved to:", paste0(report_file, ".rds"), "\n"))
      
      # Generate summary report
      generate_qc_summary_report(qc_results, paste0(report_file, "_summary.txt"))
      cat(paste("✓ Summary QC report saved to:", paste0(report_file, "_summary.txt"), "\n"))
      
      # Generate CSV reports for specific findings
      generate_qc_csv_reports(qc_results, output_dir, timestamp)
    }
    
    # Close connection
    close_database_connection(conn)
    cat("\n✓ Database connection closed\n")
    
    # Exit with appropriate code
    exit_code <- determine_exit_code(qc_results)
    
    if (exit_code == 0) {
      cat("\n✓ All quality control checks passed\n")
    } else if (exit_code == 1) {
      cat("\n⚠ Quality control checks completed with warnings\n")
    } else {
      cat("\n✗ Quality control checks failed\n")
    }
    
    cat("\n=== Quality control checks completed ===\n")
    quit("no", status = exit_code)
    
  }, error = function(e) {
    cat(paste("✗ Error:", e$message, "\n"))
    
    # Close connection if it exists
    if (exists("conn") && !is.null(conn)) {
      close_database_connection(conn)
    }
    
    quit("no", status = 2)
  })
}

# Helper functions
display_check_status <- function(check_name, status) {
  icon <- switch(status,
                 "PASS" = "✓",
                 "WARNING" = "⚠",
                 "FAIL" = "✗",
                 "?")
  
  cat(paste(icon, check_name, ":", status, "\n"))
}

display_detailed_results <- function(qc_results) {
  # Display detailed results for failed or warning checks
  
  check_sections <- list(
    "Completeness" = qc_results$completeness,
    "Consistency" = qc_results$consistency,
    "Validity" = qc_results$validity,
    "Business Rules" = qc_results$business_rules
  )
  
  for (section_name in names(check_sections)) {
    section <- check_sections[[section_name]]
    
    if (!is.null(section) && section$overall_status %in% c("FAIL", "WARNING")) {
      cat(paste("\n", section_name, "Issues:\n"))
      display_section_issues(section)
    }
  }
}

display_section_issues <- function(section) {
  # Display issues for a specific section (implement based on section structure)
  if (!is.null(section$table_results)) {
    for (table_name in names(section$table_results)) {
      table_result <- section$table_results[[table_name]]
      
      if (!is.null(table_result$field_results)) {
        for (field_name in names(table_result$field_results)) {
          field_result <- table_result$field_results[[field_name]]
          
          if (!is.null(field_result$status) && field_result$status %in% c("FAIL", "WARNING")) {
            cat(paste("- ", table_name, ".", field_name, ": ", field_result$status, "\n"))
            
            if (!is.null(field_result$completeness_rate)) {
              cat(paste("  Completeness: ", field_result$completeness_rate, "%\n"))
            }
          }
        }
      }
    }
  }
  
  if (!is.null(section$check_results)) {
    for (check_name in names(section$check_results)) {
      check_result <- section$check_results[[check_name]]
      
      if (is.list(check_result) && !is.null(check_result$status) && 
          check_result$status %in% c("FAIL", "WARNING")) {
        cat(paste("- ", check_name, ": ", check_result$status, "\n"))
        
        if (!is.null(check_result$message)) {
          cat(paste("  ", check_result$message, "\n"))
        }
      }
    }
  }
}

determine_exit_code <- function(qc_results) {
  # Determine appropriate exit code based on results
  all_statuses <- c()
  
  check_sections <- list(
    qc_results$completeness,
    qc_results$consistency,
    qc_results$validity,
    qc_results$business_rules
  )
  
  for (section in check_sections) {
    if (!is.null(section) && !is.null(section$overall_status)) {
      all_statuses <- c(all_statuses, section$overall_status)
    }
  }
  
  if (any(all_statuses == "FAIL")) {
    return(2)  # Failure
  } else if (any(all_statuses == "WARNING")) {
    return(1)  # Warning
  } else {
    return(0)  # Success
  }
}

generate_qc_csv_reports <- function(qc_results, output_dir, timestamp) {
  # Generate CSV files for specific findings
  
  # Completeness issues
  if (!is.null(qc_results$completeness) && !is.null(qc_results$completeness$table_results)) {
    completeness_data <- extract_completeness_data(qc_results$completeness$table_results)
    if (nrow(completeness_data) > 0) {
      csv_file <- file.path(output_dir, paste0("completeness_issues_", timestamp, ".csv"))
      write.csv(completeness_data, csv_file, row.names = FALSE)
      cat(paste("✓ Completeness issues exported to:", csv_file, "\n"))
    }
  }
  
  # Consistency issues
  if (!is.null(qc_results$consistency) && !is.null(qc_results$consistency$check_results)) {
    consistency_data <- extract_consistency_data(qc_results$consistency$check_results)
    if (nrow(consistency_data) > 0) {
      csv_file <- file.path(output_dir, paste0("consistency_issues_", timestamp, ".csv"))
      write.csv(consistency_data, csv_file, row.names = FALSE)
      cat(paste("✓ Consistency issues exported to:", csv_file, "\n"))
    }
  }
}

extract_completeness_data <- function(table_results) {
  # Extract completeness data for CSV export
  completeness_df <- data.frame(
    table_name = character(),
    field_name = character(),
    completeness_rate = numeric(),
    status = character(),
    stringsAsFactors = FALSE
  )
  
  for (table_name in names(table_results)) {
    table_result <- table_results[[table_name]]
    
    if (!is.null(table_result$field_results)) {
      for (field_name in names(table_result$field_results)) {
        field_result <- table_result$field_results[[field_name]]
        
        if (!is.null(field_result$completeness_rate)) {
          completeness_df <- rbind(completeness_df, data.frame(
            table_name = table_name,
            field_name = field_name,
            completeness_rate = field_result$completeness_rate,
            status = field_result$status,
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }
  
  return(completeness_df)
}

extract_consistency_data <- function(check_results) {
  # Extract consistency data for CSV export
  consistency_df <- data.frame(
    check_name = character(),
    status = character(),
    details = character(),
    stringsAsFactors = FALSE
  )
  
  for (check_name in names(check_results)) {
    check_result <- check_results[[check_name]]
    
    if (is.list(check_result) && !is.null(check_result$status)) {
      details <- if (!is.null(check_result$message)) check_result$message else "No details available"
      
      consistency_df <- rbind(consistency_df, data.frame(
        check_name = check_name,
        status = check_result$status,
        details = details,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  return(consistency_df)
}

# Usage information
if (length(args) == 0 || args[1] %in% c("-h", "--help")) {
  cat("GBIF Collections Registry - Quality Control Checks Script\n\n")
  cat("Usage: Rscript run_qc_checks.R [ENVIRONMENT] [OUTPUT_DIR] [CHECK_TYPES] [GENERATE_REPORT]\n\n")
  cat("Parameters:\n")
  cat("  ENVIRONMENT     Database environment: 'PROD' or 'TEST' (default: 'TEST')\n")
  cat("  OUTPUT_DIR      Output directory for reports (default: 'output')\n")
  cat("  CHECK_TYPES     Comma-separated list of check types (default: 'all')\n")
  cat("                  Options: 'all', 'completeness', 'consistency', 'validity', 'business_rules'\n")
  cat("  GENERATE_REPORT Generate comprehensive report: TRUE/FALSE (default: TRUE)\n\n")
  cat("Examples:\n")
  cat("  Rscript run_qc_checks.R TEST\n")
  cat("  Rscript run_qc_checks.R PROD output all TRUE\n")
  cat("  Rscript run_qc_checks.R TEST reports completeness,consistency FALSE\n\n")
  cat("Exit Codes:\n")
  cat("  0: All checks passed\n")
  cat("  1: Checks completed with warnings\n")
  cat("  2: Checks failed or script error\n\n")
  quit("no")
}

# Run main function
main()