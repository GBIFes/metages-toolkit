# Database Updates Script
# This script performs safe database updates on the GBIF Collections Registry database

# Load required modules
source("src/connection/db_connection.R")
source("src/updates/db_updates.R")

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Default parameters
environment <- if (length(args) >= 1) args[1] else "TEST"
operation <- if (length(args) >= 2) args[2] else "help"
data_file <- if (length(args) >= 3) args[3] else NULL
backup_before <- if (length(args) >= 4) as.logical(args[4]) else TRUE

# Validate environment parameter
if (!environment %in% c("PROD", "TEST")) {
  stop("Environment must be either 'PROD' or 'TEST'")
}

# Validate operation
valid_operations <- c("help", "validate", "update_collection", "update_institution", "bulk_update")
if (!operation %in% valid_operations) {
  stop(paste("Invalid operation. Valid operations:", paste(valid_operations, collapse = ", ")))
}

# Main execution
main <- function() {
  if (operation == "help") {
    show_help()
    return()
  }
  
  cat("=== GBIF Collections Registry - Database Updates ===\n")
  cat(paste("Environment:", environment, "\n"))
  cat(paste("Operation:", operation, "\n"))
  if (!is.null(data_file)) {
    cat(paste("Data file:", data_file, "\n"))
  }
  cat(paste("Backup before update:", backup_before, "\n"))
  cat("\n")
  
  # Safety check for PROD environment
  if (environment == "PROD") {
    cat("⚠ WARNING: You are about to perform updates on PRODUCTION database!\n")
    cat("Are you sure you want to continue? (yes/no): ")
    
    # Read user confirmation
    confirmation <- readline()
    if (tolower(confirmation) != "yes") {
      cat("Operation cancelled by user.\n")
      return()
    }
    cat("\n")
  }
  
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
    
    # Execute requested operation
    result <- switch(operation,
      "validate" = perform_validation(conn, data_file),
      "update_collection" = perform_collection_update(conn, data_file, backup_before),
      "update_institution" = perform_institution_update(conn, data_file, backup_before),
      "bulk_update" = perform_bulk_update(conn, data_file, backup_before)
    )
    
    # Display results
    if (!is.null(result)) {
      display_operation_results(result)
    }
    
    # Close connection
    close_database_connection(conn)
    cat("\n✓ Database connection closed\n")
    
    # Determine exit code
    exit_code <- if (!is.null(result) && result$success) 0 else 1
    
    cat("\n=== Database updates completed ===\n")
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

# Operation functions
perform_validation <- function(conn, data_file) {
  if (is.null(data_file)) {
    stop("Data file is required for validation operation")
  }
  
  cat(paste("Loading data from:", data_file, "\n"))
  
  # Load data based on file extension
  update_data <- load_update_data(data_file)
  
  # Determine table name (could be from filename or data structure)
  table_name <- determine_table_name(data_file, update_data)
  
  cat(paste("Validating data for table:", table_name, "\n"))
  
  # Perform validation
  validation_result <- validate_update_data(conn, table_name, update_data)
  
  cat("Validation Results:\n")
  cat(paste("- Validation passed:", validation_result$validation_passed, "\n"))
  
  if (length(validation_result$errors) > 0) {
    cat("Errors:\n")
    for (error in validation_result$errors) {
      cat(paste("  -", error, "\n"))
    }
  }
  
  if (length(validation_result$warnings) > 0) {
    cat("Warnings:\n")
    for (warning in validation_result$warnings) {
      cat(paste("  -", warning, "\n"))
    }
  }
  
  return(validation_result)
}

perform_collection_update <- function(conn, data_file, backup_before) {
  if (is.null(data_file)) {
    stop("Data file is required for collection update operation")
  }
  
  cat(paste("Loading collection update data from:", data_file, "\n"))
  
  # Load and parse update data
  update_data <- load_update_data(data_file)
  
  # Extract collection key and update data
  if (!"key" %in% names(update_data)) {
    stop("Collection key is required in update data")
  }
  
  collection_key <- update_data$key[1]  # Assume single record update
  
  cat(paste("Updating collection:", collection_key, "\n"))
  
  # Create backup if requested
  backup_id <- NULL
  if (backup_before) {
    cat("Creating backup...\n")
    backup_id <- backup_before_update(conn, "collections")
    cat(paste("✓ Backup created with ID:", backup_id, "\n"))
  }
  
  # Perform update
  update_result <- update_collection_record(conn, collection_key, update_data)
  
  # Log operation
  if (update_result$success) {
    log_update_operations(conn, list(
      operation = "update_collection",
      table_name = "collections",
      affected_keys = collection_key,
      success = TRUE,
      backup_id = backup_id
    ))
  }
  
  return(update_result)
}

perform_institution_update <- function(conn, data_file, backup_before) {
  if (is.null(data_file)) {
    stop("Data file is required for institution update operation")
  }
  
  cat(paste("Loading institution update data from:", data_file, "\n"))
  
  # Load and parse update data
  update_data <- load_update_data(data_file)
  
  # Extract institution key and update data
  if (!"key" %in% names(update_data)) {
    stop("Institution key is required in update data")
  }
  
  institution_key <- update_data$key[1]  # Assume single record update
  
  cat(paste("Updating institution:", institution_key, "\n"))
  
  # Create backup if requested
  backup_id <- NULL
  if (backup_before) {
    cat("Creating backup...\n")
    backup_id <- backup_before_update(conn, "institutions")
    cat(paste("✓ Backup created with ID:", backup_id, "\n"))
  }
  
  # Perform update
  update_result <- update_institution_record(conn, institution_key, update_data)
  
  # Log operation
  if (update_result$success) {
    log_update_operations(conn, list(
      operation = "update_institution",
      table_name = "institutions",
      affected_keys = institution_key,
      success = TRUE,
      backup_id = backup_id
    ))
  }
  
  return(update_result)
}

perform_bulk_update <- function(conn, data_file, backup_before) {
  if (is.null(data_file)) {
    stop("Data file is required for bulk update operation")
  }
  
  cat(paste("Loading bulk update data from:", data_file, "\n"))
  
  # Load data
  update_data <- load_update_data(data_file)
  
  # Determine table name
  table_name <- determine_table_name(data_file, update_data)
  
  cat(paste("Performing bulk update for table:", table_name, "\n"))
  cat(paste("Number of records to update:", nrow(update_data), "\n"))
  
  # Perform bulk update (backup is handled within the function)
  bulk_result <- bulk_update_records(conn, table_name, update_data)
  
  return(bulk_result)
}

# Helper functions
load_update_data <- function(data_file) {
  if (!file.exists(data_file)) {
    stop(paste("Data file not found:", data_file))
  }
  
  file_ext <- tools::file_ext(data_file)
  
  update_data <- switch(tolower(file_ext),
    "csv" = read.csv(data_file, stringsAsFactors = FALSE),
    "rds" = readRDS(data_file),
    "json" = jsonlite::fromJSON(data_file),
    stop(paste("Unsupported file format:", file_ext))
  )
  
  # Convert to data frame if needed
  if (is.list(update_data) && !is.data.frame(update_data)) {
    update_data <- data.frame(update_data, stringsAsFactors = FALSE)
  }
  
  return(update_data)
}

determine_table_name <- function(data_file, update_data) {
  # Try to determine table name from filename
  basename_file <- basename(data_file)
  
  if (grepl("collection", basename_file, ignore.case = TRUE)) {
    return("collections")
  } else if (grepl("institution", basename_file, ignore.case = TRUE)) {
    return("institutions")
  } else if (grepl("contact", basename_file, ignore.case = TRUE)) {
    return("contacts")
  } else if (grepl("identifier", basename_file, ignore.case = TRUE)) {
    return("identifiers")
  }
  
  # Try to determine from data structure
  if ("institution_key" %in% names(update_data)) {
    return("collections")
  } else if ("code" %in% names(update_data) && !"institution_key" %in% names(update_data)) {
    return("institutions")
  }
  
  # Default or prompt user
  cat("Cannot determine table name automatically.\n")
  cat("Available tables: collections, institutions, contacts, identifiers\n")
  cat("Please enter table name: ")
  table_name <- readline()
  
  return(table_name)
}

display_operation_results <- function(result) {
  cat("\nOperation Results:\n")
  cat(paste("- Success:", result$success, "\n"))
  
  if (!is.null(result$rows_affected)) {
    cat(paste("- Rows affected:", result$rows_affected, "\n"))
  }
  
  if (!is.null(result$successful_updates)) {
    cat(paste("- Successful updates:", result$successful_updates, "\n"))
  }
  
  if (!is.null(result$failed_updates)) {
    cat(paste("- Failed updates:", result$failed_updates, "\n"))
  }
  
  if (!is.null(result$success_rate)) {
    cat(paste("- Success rate:", result$success_rate, "%\n"))
  }
  
  if (!is.null(result$backup_id)) {
    cat(paste("- Backup ID:", result$backup_id, "\n"))
  }
  
  # Display errors if any
  if (!is.null(result$errors) && length(result$errors) > 0) {
    cat("Errors:\n")
    if (is.character(result$errors)) {
      for (error in result$errors) {
        cat(paste("  -", error, "\n"))
      }
    } else if (is.list(result$errors)) {
      for (error_group in names(result$errors)) {
        cat(paste("  ", error_group, ":\n"))
        for (error in result$errors[[error_group]]) {
          cat(paste("    -", error, "\n"))
        }
      }
    }
  }
  
  # Display validation results if available
  if (!is.null(result$validation)) {
    cat("Validation:\n")
    cat(paste("  - Passed:", result$validation$validation_passed, "\n"))
    if (length(result$validation$warnings) > 0) {
      cat("  Warnings:\n")
      for (warning in result$validation$warnings) {
        cat(paste("    -", warning, "\n"))
      }
    }
  }
}

show_help <- function() {
  cat("GBIF Collections Registry - Database Updates Script\n\n")
  cat("Usage: Rscript run_updates.R [ENVIRONMENT] [OPERATION] [DATA_FILE] [BACKUP_BEFORE]\n\n")
  cat("Parameters:\n")
  cat("  ENVIRONMENT     Database environment: 'PROD' or 'TEST' (default: 'TEST')\n")
  cat("  OPERATION       Update operation to perform:\n")
  cat("                  - 'validate': Validate update data without performing updates\n")
  cat("                  - 'update_collection': Update a single collection record\n")
  cat("                  - 'update_institution': Update a single institution record\n")
  cat("                  - 'bulk_update': Perform bulk updates from file\n")
  cat("                  - 'help': Show this help message\n")
  cat("  DATA_FILE       Path to data file (CSV, RDS, or JSON format)\n")
  cat("  BACKUP_BEFORE   Create backup before update: TRUE/FALSE (default: TRUE)\n\n")
  cat("Data File Formats:\n")
  cat("  - CSV: Comma-separated values with headers\n")
  cat("  - RDS: R data structure (data.frame or list)\n")
  cat("  - JSON: JSON object or array\n\n")
  cat("Examples:\n")
  cat("  # Validate update data\n")
  cat("  Rscript run_updates.R TEST validate collection_updates.csv\n\n")
  cat("  # Update single collection\n")
  cat("  Rscript run_updates.R TEST update_collection single_collection.csv TRUE\n\n")
  cat("  # Bulk update (with backup)\n")
  cat("  Rscript run_updates.R PROD bulk_update bulk_collections.csv TRUE\n\n")
  cat("Safety Notes:\n")
  cat("  - Always test updates on TEST environment first\n")
  cat("  - Backups are created automatically for bulk operations\n")
  cat("  - PROD environment requires explicit confirmation\n")
  cat("  - All operations are logged for audit trail\n\n")
  cat("Required Data Fields:\n")
  cat("  Collections: key (required), name, institution_key, etc.\n")
  cat("  Institutions: key (required), name, code, etc.\n")
  cat("  See documentation for complete field specifications.\n\n")
}

# Usage information
if (length(args) == 0 || (length(args) >= 2 && args[2] == "help")) {
  show_help()
  quit("no")
}

# Run main function
main()