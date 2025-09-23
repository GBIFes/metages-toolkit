# Database Updates Module for GBIF Collections Registry
# This module provides safe database update operations with validation and logging

# Load required libraries
library(DBI)
library(dplyr)
library(lubridate)
library(uuid)
library(logging)

#' Validate Update Data
#' 
#' Validates data before performing updates
#' 
#' @param connection Database connection object
#' @param table_name Character. Name of the table to update
#' @param update_data Data frame or list with update data
#' @param validation_rules List. Custom validation rules (optional)
#' @return List with validation results
#' @export
validate_update_data <- function(connection, table_name, update_data, validation_rules = NULL) {
  loginfo("Starting data validation for updates")
  
  tryCatch({
    validation_result <- list()
    validation_result$timestamp <- Sys.time()
    validation_result$table_name <- table_name
    validation_result$validation_passed <- TRUE
    validation_result$errors <- c()
    validation_result$warnings <- c()
    
    # Check if table exists
    if (!table_name %in% dbListTables(connection)) {
      validation_result$validation_passed <- FALSE
      validation_result$errors <- c(validation_result$errors, paste("Table does not exist:", table_name))
      return(validation_result)
    }
    
    # Get table structure
    table_columns <- dbListFields(connection, table_name)
    
    # Convert update_data to data frame if it's a list
    if (is.list(update_data) && !is.data.frame(update_data)) {
      update_data <- data.frame(update_data, stringsAsFactors = FALSE)
    }
    
    # Check if update_data has required columns
    update_columns <- names(update_data)
    invalid_columns <- update_columns[!update_columns %in% table_columns]
    
    if (length(invalid_columns) > 0) {
      validation_result$validation_passed <- FALSE
      validation_result$errors <- c(validation_result$errors, 
                                   paste("Invalid columns:", paste(invalid_columns, collapse = ", ")))
    }
    
    # Check for required fields (key columns)
    key_columns <- get_table_key_columns(connection, table_name)
    missing_keys <- key_columns[!key_columns %in% update_columns]
    
    if (length(missing_keys) > 0) {
      validation_result$validation_passed <- FALSE
      validation_result$errors <- c(validation_result$errors,
                                   paste("Missing key columns:", paste(missing_keys, collapse = ", ")))
    }
    
    # Data type validation
    for (col in update_columns[update_columns %in% table_columns]) {
      col_data <- update_data[[col]]
      
      # Check for NULL values in non-nullable columns
      if (any(is.na(col_data)) && is_column_non_nullable(connection, table_name, col)) {
        validation_result$warnings <- c(validation_result$warnings,
                                       paste("NULL values found in non-nullable column:", col))
      }
      
      # Check data length constraints
      length_constraint <- get_column_length_constraint(connection, table_name, col)
      if (!is.null(length_constraint)) {
        max_length <- max(nchar(as.character(col_data)), na.rm = TRUE)
        if (max_length > length_constraint) {
          validation_result$validation_passed <- FALSE
          validation_result$errors <- c(validation_result$errors,
                                       paste("Data too long for column", col, ": max", max_length, "exceeds limit", length_constraint))
        }
      }
    }
    
    # Apply custom validation rules if provided
    if (!is.null(validation_rules)) {
      custom_validation <- apply_custom_validation_rules(update_data, validation_rules)
      validation_result$custom_validation <- custom_validation
      
      if (!custom_validation$passed) {
        validation_result$validation_passed <- FALSE
        validation_result$errors <- c(validation_result$errors, custom_validation$errors)
      }
    }
    
    # Business logic validation
    business_validation <- apply_business_validation(connection, table_name, update_data)
    validation_result$business_validation <- business_validation
    
    if (!business_validation$passed) {
      validation_result$validation_passed <- FALSE
      validation_result$errors <- c(validation_result$errors, business_validation$errors)
    }
    
    loginfo(paste("Data validation completed. Passed:", validation_result$validation_passed))
    return(validation_result)
    
  }, error = function(e) {
    logerror(paste("Error in data validation:", e$message))
    return(list(validation_passed = FALSE, errors = e$message))
  })
}

#' Update Collection Record
#' 
#' Updates a single collection record with validation
#' 
#' @param connection Database connection object
#' @param collection_key Character. Collection key to update
#' @param update_data List. Data to update
#' @param validate_first Logical. Whether to validate before update (default: TRUE)
#' @return List with update results
#' @export
update_collection_record <- function(connection, collection_key, update_data, validate_first = TRUE) {
  loginfo(paste("Updating collection record:", collection_key))
  
  tryCatch({
    update_result <- list()
    update_result$timestamp <- Sys.time()
    update_result$operation <- "update_collection"
    update_result$collection_key <- collection_key
    update_result$success <- FALSE
    
    # Add collection key to update data if not present
    if (!"key" %in% names(update_data)) {
      update_data$key <- collection_key
    }
    
    # Validate data first if requested
    if (validate_first) {
      validation <- validate_update_data(connection, "collections", update_data)
      update_result$validation <- validation
      
      if (!validation$validation_passed) {
        update_result$errors <- validation$errors
        logwarn("Validation failed for collection update")
        return(update_result)
      }
    }
    
    # Check if collection exists
    exists_query <- "SELECT COUNT(*) as count FROM collections WHERE key = ?"
    exists_result <- execute_safe_query(connection, exists_query, list(collection_key))
    
    if (exists_result$count == 0) {
      update_result$errors <- "Collection not found"
      logwarn(paste("Collection not found:", collection_key))
      return(update_result)
    }
    
    # Create backup of current record
    backup_query <- "SELECT * FROM collections WHERE key = ?"
    backup_data <- execute_safe_query(connection, backup_query, list(collection_key))
    update_result$backup_data <- backup_data
    
    # Prepare update query
    update_fields <- names(update_data)[names(update_data) != "key"]
    set_clause <- paste(paste(update_fields, "= ?"), collapse = ", ")
    update_query <- paste("UPDATE collections SET", set_clause, "WHERE key = ?")
    
    # Prepare parameters (field values + key)
    params <- c(update_data[update_fields], collection_key)
    
    # Execute update
    dbBegin(connection)
    
    tryCatch({
      update_rows <- dbExecute(connection, update_query, params)
      
      if (update_rows > 0) {
        # Update the modified timestamp
        timestamp_query <- "UPDATE collections SET modified = NOW() WHERE key = ?"
        dbExecute(connection, timestamp_query, list(collection_key))
        
        dbCommit(connection)
        update_result$success <- TRUE
        update_result$rows_affected <- update_rows
        
        loginfo(paste("Collection record updated successfully:", collection_key))
      } else {
        dbRollback(connection)
        update_result$errors <- "No rows were updated"
        logwarn("No rows were updated")
      }
      
    }, error = function(e) {
      dbRollback(connection)
      update_result$errors <- e$message
      logerror(paste("Error executing update:", e$message))
    })
    
    return(update_result)
    
  }, error = function(e) {
    logerror(paste("Error in collection record update:", e$message))
    return(list(success = FALSE, errors = e$message))
  })
}

#' Update Institution Record
#' 
#' Updates a single institution record with validation
#' 
#' @param connection Database connection object
#' @param institution_key Character. Institution key to update
#' @param update_data List. Data to update
#' @param validate_first Logical. Whether to validate before update (default: TRUE)
#' @return List with update results
#' @export
update_institution_record <- function(connection, institution_key, update_data, validate_first = TRUE) {
  loginfo(paste("Updating institution record:", institution_key))
  
  tryCatch({
    update_result <- list()
    update_result$timestamp <- Sys.time()
    update_result$operation <- "update_institution"
    update_result$institution_key <- institution_key
    update_result$success <- FALSE
    
    # Add institution key to update data if not present
    if (!"key" %in% names(update_data)) {
      update_data$key <- institution_key
    }
    
    # Validate data first if requested
    if (validate_first) {
      validation <- validate_update_data(connection, "institutions", update_data)
      update_result$validation <- validation
      
      if (!validation$validation_passed) {
        update_result$errors <- validation$errors
        logwarn("Validation failed for institution update")
        return(update_result)
      }
    }
    
    # Check if institution exists
    exists_query <- "SELECT COUNT(*) as count FROM institutions WHERE key = ?"
    exists_result <- execute_safe_query(connection, exists_query, list(institution_key))
    
    if (exists_result$count == 0) {
      update_result$errors <- "Institution not found"
      logwarn(paste("Institution not found:", institution_key))
      return(update_result)
    }
    
    # Create backup of current record
    backup_query <- "SELECT * FROM institutions WHERE key = ?"
    backup_data <- execute_safe_query(connection, backup_query, list(institution_key))
    update_result$backup_data <- backup_data
    
    # Check for dependent collections
    collections_query <- "SELECT COUNT(*) as count FROM collections WHERE institution_key = ?"
    collections_count <- execute_safe_query(connection, collections_query, list(institution_key))$count
    update_result$dependent_collections <- collections_count
    
    # Prepare update query
    update_fields <- names(update_data)[names(update_data) != "key"]
    set_clause <- paste(paste(update_fields, "= ?"), collapse = ", ")
    update_query <- paste("UPDATE institutions SET", set_clause, "WHERE key = ?")
    
    # Prepare parameters
    params <- c(update_data[update_fields], institution_key)
    
    # Execute update
    dbBegin(connection)
    
    tryCatch({
      update_rows <- dbExecute(connection, update_query, params)
      
      if (update_rows > 0) {
        # Update the modified timestamp
        timestamp_query <- "UPDATE institutions SET modified = NOW() WHERE key = ?"
        dbExecute(connection, timestamp_query, list(institution_key))
        
        dbCommit(connection)
        update_result$success <- TRUE
        update_result$rows_affected <- update_rows
        
        loginfo(paste("Institution record updated successfully:", institution_key))
      } else {
        dbRollback(connection)
        update_result$errors <- "No rows were updated"
        logwarn("No rows were updated")
      }
      
    }, error = function(e) {
      dbRollback(connection)
      update_result$errors <- e$message
      logerror(paste("Error executing update:", e$message))
    })
    
    return(update_result)
    
  }, error = function(e) {
    logerror(paste("Error in institution record update:", e$message))
    return(list(success = FALSE, errors = e$message))
  })
}

#' Bulk Update Records
#' 
#' Performs bulk updates with validation and error handling
#' 
#' @param connection Database connection object
#' @param table_name Character. Name of the table to update
#' @param update_data Data frame. Records to update (must include key column)
#' @param batch_size Numeric. Number of records to process per batch (default: 100)
#' @return List with bulk update results
#' @export
bulk_update_records <- function(connection, table_name, update_data, batch_size = 100) {
  loginfo(paste("Starting bulk update for table:", table_name))
  
  tryCatch({
    bulk_result <- list()
    bulk_result$timestamp <- Sys.time()
    bulk_result$operation <- "bulk_update"
    bulk_result$table_name <- table_name
    bulk_result$total_records <- nrow(update_data)
    bulk_result$success <- FALSE
    bulk_result$successful_updates <- 0
    bulk_result$failed_updates <- 0
    bulk_result$errors <- list()
    
    # Validate all data first
    validation <- validate_update_data(connection, table_name, update_data)
    bulk_result$validation <- validation
    
    if (!validation$validation_passed) {
      bulk_result$errors$validation <- validation$errors
      logwarn("Bulk validation failed")
      return(bulk_result)
    }
    
    # Create backup
    backup_id <- backup_before_update(connection, table_name)
    bulk_result$backup_id <- backup_id
    
    # Process in batches
    total_rows <- nrow(update_data)
    batches <- split(1:total_rows, ceiling(seq_along(1:total_rows) / batch_size))
    
    for (batch_num in seq_along(batches)) {
      loginfo(paste("Processing batch", batch_num, "of", length(batches)))
      
      batch_indices <- batches[[batch_num]]
      batch_data <- update_data[batch_indices, ]
      
      batch_result <- process_update_batch(connection, table_name, batch_data)
      
      bulk_result$successful_updates <- bulk_result$successful_updates + batch_result$successful
      bulk_result$failed_updates <- bulk_result$failed_updates + batch_result$failed
      
      if (length(batch_result$errors) > 0) {
        bulk_result$errors[[paste0("batch_", batch_num)]] <- batch_result$errors
      }
    }
    
    # Determine overall success
    bulk_result$success <- bulk_result$failed_updates == 0
    bulk_result$success_rate <- round(bulk_result$successful_updates / bulk_result$total_records * 100, 2)
    
    loginfo(paste("Bulk update completed. Success rate:", bulk_result$success_rate, "%"))
    return(bulk_result)
    
  }, error = function(e) {
    logerror(paste("Error in bulk update:", e$message))
    return(list(success = FALSE, errors = e$message))
  })
}

#' Backup Before Update
#' 
#' Creates a backup of table data before performing updates
#' 
#' @param connection Database connection object
#' @param table_name Character. Name of the table to backup
#' @param backup_name Character. Custom backup name (optional)
#' @return Character. Backup identifier
#' @export
backup_before_update <- function(connection, table_name, backup_name = NULL) {
  loginfo(paste("Creating backup for table:", table_name))
  
  tryCatch({
    # Generate unique backup identifier
    backup_id <- if (is.null(backup_name)) {
      paste0(table_name, "_backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", substr(UUIDgenerate(), 1, 8))
    } else {
      backup_name
    }
    
    # Create backup table
    backup_table_name <- paste0("backup_", backup_id)
    create_backup_query <- paste("CREATE TABLE", backup_table_name, "AS SELECT * FROM", table_name)
    
    dbExecute(connection, create_backup_query)
    
    # Log backup creation
    log_backup_creation(connection, backup_id, table_name, backup_table_name)
    
    loginfo(paste("Backup created with ID:", backup_id))
    return(backup_id)
    
  }, error = function(e) {
    logerror(paste("Error creating backup:", e$message))
    stop(e)
  })
}

#' Rollback Updates
#' 
#' Rollback updates using a backup
#' 
#' @param connection Database connection object
#' @param backup_id Character. Backup identifier
#' @return Logical. Whether rollback was successful
#' @export
rollback_updates <- function(connection, backup_id) {
  loginfo(paste("Rolling back updates using backup:", backup_id))
  
  tryCatch({
    # Get backup information
    backup_info <- get_backup_info(connection, backup_id)
    
    if (is.null(backup_info)) {
      logerror("Backup not found")
      return(FALSE)
    }
    
    original_table <- backup_info$original_table
    backup_table <- backup_info$backup_table
    
    # Verify backup table exists
    if (!backup_table %in% dbListTables(connection)) {
      logerror("Backup table not found")
      return(FALSE)
    }
    
    # Begin transaction
    dbBegin(connection)
    
    tryCatch({
      # Delete current data
      delete_query <- paste("DELETE FROM", original_table)
      dbExecute(connection, delete_query)
      
      # Restore from backup
      restore_query <- paste("INSERT INTO", original_table, "SELECT * FROM", backup_table)
      dbExecute(connection, restore_query)
      
      dbCommit(connection)
      
      # Log rollback
      log_rollback_operation(connection, backup_id)
      
      loginfo("Rollback completed successfully")
      return(TRUE)
      
    }, error = function(e) {
      dbRollback(connection)
      logerror(paste("Error during rollback:", e$message))
      return(FALSE)
    })
    
  }, error = function(e) {
    logerror(paste("Error in rollback operation:", e$message))
    return(FALSE)
  })
}

#' Log Update Operations
#' 
#' Logs update operations for audit trail
#' 
#' @param connection Database connection object
#' @param operation_details List. Details of the operation
#' @export
log_update_operations <- function(connection, operation_details) {
  tryCatch({
    # Create operations log table if it doesn't exist
    create_log_table_if_not_exists(connection)
    
    # Prepare log entry
    log_entry <- list(
      operation_id = UUIDgenerate(),
      timestamp = Sys.time(),
      operation_type = operation_details$operation,
      table_name = operation_details$table_name %||% "unknown",
      affected_keys = paste(operation_details$affected_keys %||% "unknown", collapse = ","),
      success = operation_details$success,
      details = jsonlite::toJSON(operation_details, auto_unbox = TRUE)
    )
    
    # Insert log entry
    insert_log_query <- "
      INSERT INTO update_operations_log 
      (operation_id, timestamp, operation_type, table_name, affected_keys, success, details)
      VALUES (?, ?, ?, ?, ?, ?, ?)"
    
    dbExecute(connection, insert_log_query, unlist(log_entry))
    
    loginfo("Update operation logged successfully")
    
  }, error = function(e) {
    logwarn(paste("Error logging update operation:", e$message))
  })
}

# Helper functions

get_table_key_columns <- function(connection, table_name) {
  # Get primary key columns for the table
  key_query <- "
    SELECT column_name 
    FROM information_schema.key_column_usage 
    WHERE table_schema = DATABASE() 
    AND table_name = ? 
    AND constraint_name = 'PRIMARY'"
  
  result <- execute_safe_query(connection, key_query, list(table_name))
  return(if (is.null(result)) character(0) else result$column_name)
}

is_column_non_nullable <- function(connection, table_name, column_name) {
  nullable_query <- "
    SELECT is_nullable 
    FROM information_schema.columns 
    WHERE table_schema = DATABASE() 
    AND table_name = ? 
    AND column_name = ?"
  
  result <- execute_safe_query(connection, nullable_query, list(table_name, column_name))
  return(if (is.null(result)) FALSE else result$is_nullable == "NO")
}

get_column_length_constraint <- function(connection, table_name, column_name) {
  length_query <- "
    SELECT character_maximum_length 
    FROM information_schema.columns 
    WHERE table_schema = DATABASE() 
    AND table_name = ? 
    AND column_name = ?"
  
  result <- execute_safe_query(connection, length_query, list(table_name, column_name))
  return(if (is.null(result)) NULL else result$character_maximum_length)
}

apply_custom_validation_rules <- function(data, rules) {
  # Apply custom validation rules (implement based on specific needs)
  return(list(passed = TRUE, errors = character(0)))
}

apply_business_validation <- function(connection, table_name, data) {
  # Apply business logic validation (implement based on GBIF requirements)
  return(list(passed = TRUE, errors = character(0)))
}

process_update_batch <- function(connection, table_name, batch_data) {
  # Process a batch of updates
  batch_result <- list(successful = 0, failed = 0, errors = c())
  
  for (i in 1:nrow(batch_data)) {
    row_data <- as.list(batch_data[i, ])
    
    # Perform individual update based on table
    if (table_name == "collections") {
      update_result <- update_collection_record(connection, row_data$key, row_data, validate_first = FALSE)
    } else if (table_name == "institutions") {
      update_result <- update_institution_record(connection, row_data$key, row_data, validate_first = FALSE)
    } else {
      # Generic update for other tables
      update_result <- list(success = FALSE, errors = "Unsupported table for bulk update")
    }
    
    if (update_result$success) {
      batch_result$successful <- batch_result$successful + 1
    } else {
      batch_result$failed <- batch_result$failed + 1
      batch_result$errors <- c(batch_result$errors, update_result$errors)
    }
  }
  
  return(batch_result)
}

create_log_table_if_not_exists <- function(connection) {
  # Create update operations log table if it doesn't exist
  create_table_query <- "
    CREATE TABLE IF NOT EXISTS update_operations_log (
      id INT AUTO_INCREMENT PRIMARY KEY,
      operation_id VARCHAR(36) NOT NULL,
      timestamp TIMESTAMP NOT NULL,
      operation_type VARCHAR(50) NOT NULL,
      table_name VARCHAR(100) NOT NULL,
      affected_keys TEXT,
      success BOOLEAN NOT NULL,
      details JSON,
      INDEX idx_timestamp (timestamp),
      INDEX idx_operation_type (operation_type),
      INDEX idx_table_name (table_name)
    )"
  
  dbExecute(connection, create_table_query)
}

log_backup_creation <- function(connection, backup_id, original_table, backup_table) {
  # Log backup creation (implement based on requirements)
  loginfo(paste("Backup created:", backup_id, "for table:", original_table))
}

get_backup_info <- function(connection, backup_id) {
  # Get backup information (implement based on backup storage method)
  return(list(
    backup_id = backup_id,
    original_table = "collections",  # This would be stored/retrieved
    backup_table = paste0("backup_", backup_id)
  ))
}

log_rollback_operation <- function(connection, backup_id) {
  # Log rollback operation
  loginfo(paste("Rollback operation completed for backup:", backup_id))
}

# Utility operator for null coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a