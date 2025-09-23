# Quality Control Module for GBIF Collections Registry
# This module implements comprehensive quality control checks for data validation

# Load required libraries
library(DBI)
library(dplyr)
library(stringr)
library(lubridate)
library(logging)

#' Run Completeness Checks
#' 
#' Checks for data completeness across critical fields
#' 
#' @param connection Database connection object
#' @return List with completeness check results
#' @export
run_completeness_checks <- function(connection) {
  loginfo("Starting completeness checks")
  
  tryCatch({
    completeness_results <- list()
    completeness_results$timestamp <- Sys.time()
    completeness_results$check_type <- "completeness"
    
    # Define critical fields for each table (customize based on GBIF requirements)
    critical_fields <- list(
      collections = c("key", "name", "institution_key", "created", "modified"),
      institutions = c("key", "name", "code", "created", "modified"),
      contacts = c("key", "first_name", "last_name", "type"),
      identifiers = c("key", "identifier", "type")
    )
    
    tables <- dbListTables(connection)
    table_results <- list()
    
    for (table in tables) {
      if (table %in% names(critical_fields)) {
        loginfo(paste("Checking completeness for table:", table))
        
        table_result <- list()
        table_result$table_name <- table
        
        # Get total row count
        total_rows_query <- paste("SELECT COUNT(*) as total FROM", table)
        total_rows <- execute_safe_query(connection, total_rows_query)$total
        table_result$total_rows <- total_rows
        
        # Check each critical field
        field_results <- list()
        
        for (field in critical_fields[[table]]) {
          # Check if field exists
          columns <- dbListFields(connection, table)
          if (field %in% columns) {
            # Count non-null values
            non_null_query <- paste("SELECT COUNT(*) as non_null FROM", table, "WHERE", field, "IS NOT NULL AND", field, "!= ''")
            non_null_count <- execute_safe_query(connection, non_null_query)$non_null
            
            completeness_rate <- round(non_null_count / total_rows * 100, 2)
            
            field_result <- list(
              field_name = field,
              total_rows = total_rows,
              non_null_count = non_null_count,
              null_count = total_rows - non_null_count,
              completeness_rate = completeness_rate,
              status = if (completeness_rate >= 95) "PASS" else if (completeness_rate >= 80) "WARNING" else "FAIL"
            )
            
            field_results[[field]] <- field_result
          } else {
            field_results[[field]] <- list(
              field_name = field,
              status = "MISSING_FIELD",
              message = "Field does not exist in table"
            )
          }
        }
        
        table_result$field_results <- field_results
        table_results[[table]] <- table_result
      }
    }
    
    completeness_results$table_results <- table_results
    completeness_results$overall_status <- calculate_overall_status(table_results)
    
    loginfo("Completeness checks completed")
    return(completeness_results)
    
  }, error = function(e) {
    logerror(paste("Error in completeness checks:", e$message))
    return(NULL)
  })
}

#' Run Consistency Checks
#' 
#' Checks for data consistency and referential integrity
#' 
#' @param connection Database connection object
#' @return List with consistency check results
#' @export
run_consistency_checks <- function(connection) {
  loginfo("Starting consistency checks")
  
  tryCatch({
    consistency_results <- list()
    consistency_results$timestamp <- Sys.time()
    consistency_results$check_type <- "consistency"
    
    check_results <- list()
    
    # Check 1: Referential integrity between collections and institutions
    check_results$collections_institutions_integrity <- check_referential_integrity(
      connection, "collections", "institution_key", "institutions", "key"
    )
    
    # Check 2: Date consistency (created <= modified)
    check_results$date_consistency <- check_date_consistency(connection)
    
    # Check 3: Identifier uniqueness within type
    check_results$identifier_uniqueness <- check_identifier_uniqueness(connection)
    
    # Check 4: Contact association consistency
    check_results$contact_associations <- check_contact_associations(connection)
    
    consistency_results$check_results <- check_results
    consistency_results$overall_status <- calculate_overall_status(check_results)
    
    loginfo("Consistency checks completed")
    return(consistency_results)
    
  }, error = function(e) {
    logerror(paste("Error in consistency checks:", e$message))
    return(NULL)
  })
}

#' Run Validity Checks
#' 
#' Validates data formats and constraints
#' 
#' @param connection Database connection object
#' @return List with validity check results
#' @export
run_validity_checks <- function(connection) {
  loginfo("Starting validity checks")
  
  tryCatch({
    validity_results <- list()
    validity_results$timestamp <- Sys.time()
    validity_results$check_type <- "validity"
    
    check_results <- list()
    
    # Check 1: Email format validation
    check_results$email_format <- check_email_format(connection)
    
    # Check 2: URL format validation
    check_results$url_format <- check_url_format(connection)
    
    # Check 3: Date format validation
    check_results$date_format <- check_date_format(connection)
    
    # Check 4: Required field lengths
    check_results$field_lengths <- check_field_lengths(connection)
    
    # Check 5: Enum value validation
    check_results$enum_values <- check_enum_values(connection)
    
    validity_results$check_results <- check_results
    validity_results$overall_status <- calculate_overall_status(check_results)
    
    loginfo("Validity checks completed")
    return(validity_results)
    
  }, error = function(e) {
    logerror(paste("Error in validity checks:", e$message))
    return(NULL)
  })
}

#' Run Business Rule Checks
#' 
#' Applies GBIF-specific business rules
#' 
#' @param connection Database connection object
#' @return List with business rule check results
#' @export
run_business_rule_checks <- function(connection) {
  loginfo("Starting business rule checks")
  
  tryCatch({
    business_results <- list()
    business_results$timestamp <- Sys.time()
    business_results$check_type <- "business_rules"
    
    check_results <- list()
    
    # Check 1: Institution must have at least one contact
    check_results$institution_contacts <- check_institution_contacts(connection)
    
    # Check 2: Collection must belong to an active institution
    check_results$collection_active_institution <- check_collection_active_institution(connection)
    
    # Check 3: Identifier patterns validation
    check_results$identifier_patterns <- check_identifier_patterns(connection)
    
    # Check 4: Geographic coordinate validation
    check_results$geographic_coordinates <- check_geographic_coordinates(connection)
    
    business_results$check_results <- check_results
    business_results$overall_status <- calculate_overall_status(check_results)
    
    loginfo("Business rule checks completed")
    return(business_results)
    
  }, error = function(e) {
    logerror(paste("Error in business rule checks:", e$message))
    return(NULL)
  })
}

#' Run All QC Checks
#' 
#' Executes all quality control checks
#' 
#' @param connection Database connection object
#' @return List with all QC check results
#' @export
run_all_qc_checks <- function(connection) {
  loginfo("Starting comprehensive QC checks")
  
  tryCatch({
    all_results <- list()
    all_results$timestamp <- Sys.time()
    all_results$check_type <- "comprehensive"
    
    # Run all check types
    all_results$completeness <- run_completeness_checks(connection)
    all_results$consistency <- run_consistency_checks(connection)
    all_results$validity <- run_validity_checks(connection)
    all_results$business_rules <- run_business_rule_checks(connection)
    
    # Calculate overall status
    all_statuses <- c(
      all_results$completeness$overall_status,
      all_results$consistency$overall_status,
      all_results$validity$overall_status,
      all_results$business_rules$overall_status
    )
    
    all_results$overall_status <- if (any(all_statuses == "FAIL")) {
      "FAIL"
    } else if (any(all_statuses == "WARNING")) {
      "WARNING"
    } else {
      "PASS"
    }
    
    loginfo("Comprehensive QC checks completed")
    return(all_results)
    
  }, error = function(e) {
    logerror(paste("Error in comprehensive QC checks:", e$message))
    return(NULL)
  })
}

# Helper functions for specific checks

check_referential_integrity <- function(connection, child_table, child_key, parent_table, parent_key) {
  query <- paste(
    "SELECT COUNT(*) as orphaned_records FROM", child_table, "c",
    "LEFT JOIN", parent_table, "p ON c.", child_key, "= p.", parent_key,
    "WHERE c.", child_key, "IS NOT NULL AND p.", parent_key, "IS NULL"
  )
  
  result <- execute_safe_query(connection, query)
  orphaned_count <- result$orphaned_records
  
  return(list(
    check_name = paste("Referential integrity:", child_table, "->", parent_table),
    orphaned_records = orphaned_count,
    status = if (orphaned_count == 0) "PASS" else "FAIL"
  ))
}

check_date_consistency <- function(connection) {
  # Check tables with created and modified dates
  tables_with_dates <- c("collections", "institutions")
  
  results <- list()
  
  for (table in tables_with_dates) {
    if (table %in% dbListTables(connection)) {
      query <- paste(
        "SELECT COUNT(*) as inconsistent_dates FROM", table,
        "WHERE created > modified"
      )
      
      result <- execute_safe_query(connection, query)
      inconsistent_count <- if (is.null(result)) 0 else result$inconsistent_dates
      
      results[[table]] <- list(
        table_name = table,
        inconsistent_count = inconsistent_count,
        status = if (inconsistent_count == 0) "PASS" else "FAIL"
      )
    }
  }
  
  return(results)
}

check_identifier_uniqueness <- function(connection) {
  if (!"identifiers" %in% dbListTables(connection)) {
    return(list(status = "SKIP", message = "Identifiers table not found"))
  }
  
  query <- "
    SELECT type, identifier, COUNT(*) as count 
    FROM identifiers 
    GROUP BY type, identifier 
    HAVING COUNT(*) > 1"
  
  duplicates <- execute_safe_query(connection, query)
  duplicate_count <- if (is.null(duplicates)) 0 else nrow(duplicates)
  
  return(list(
    check_name = "Identifier uniqueness within type",
    duplicate_count = duplicate_count,
    duplicates = duplicates,
    status = if (duplicate_count == 0) "PASS" else "FAIL"
  ))
}

check_email_format <- function(connection) {
  # Check email format in contacts table
  if (!"contacts" %in% dbListTables(connection)) {
    return(list(status = "SKIP", message = "Contacts table not found"))
  }
  
  columns <- dbListFields(connection, "contacts")
  email_columns <- columns[grepl("email", columns, ignore.case = TRUE)]
  
  results <- list()
  
  for (email_col in email_columns) {
    query <- paste(
      "SELECT COUNT(*) as invalid_emails FROM contacts",
      "WHERE", email_col, "IS NOT NULL",
      "AND", email_col, "!= ''",
      "AND", email_col, "NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'"
    )
    
    result <- execute_safe_query(connection, query)
    invalid_count <- if (is.null(result)) 0 else result$invalid_emails
    
    results[[email_col]] <- list(
      column_name = email_col,
      invalid_count = invalid_count,
      status = if (invalid_count == 0) "PASS" else "FAIL"
    )
  }
  
  return(results)
}

# Additional helper functions would be implemented here...
# (URL validation, date format validation, etc.)

calculate_overall_status <- function(results) {
  if (is.null(results) || length(results) == 0) {
    return("UNKNOWN")
  }
  
  statuses <- unlist(lapply(results, function(x) {
    if (is.list(x) && "status" %in% names(x)) {
      return(x$status)
    } else if (is.list(x)) {
      # Recursively check nested results
      return(calculate_overall_status(x))
    } else {
      return("UNKNOWN")
    }
  }))
  
  if (any(statuses == "FAIL")) {
    return("FAIL")
  } else if (any(statuses == "WARNING")) {
    return("WARNING")
  } else if (all(statuses == "PASS")) {
    return("PASS")
  } else {
    return("UNKNOWN")
  }
}

#' Generate QC Report
#' 
#' Creates a comprehensive quality control report
#' 
#' @param connection Database connection object
#' @param output_file Character. Path to save the report (optional)
#' @return List with QC report
#' @export
generate_qc_report <- function(connection, output_file = NULL) {
  loginfo("Generating QC report")
  
  tryCatch({
    # Run all checks
    qc_results <- run_all_qc_checks(connection)
    
    # Add metadata
    qc_results$report_metadata <- list(
      generated_at = Sys.time(),
      connection_info = get_connection_info(connection),
      database_name = execute_safe_query(connection, "SELECT DATABASE() as db_name")$db_name
    )
    
    # Save report if output file specified
    if (!is.null(output_file)) {
      saveRDS(qc_results, paste0(output_file, ".rds"))
      
      # Also create a summary text report
      create_qc_summary_report(qc_results, paste0(output_file, "_summary.txt"))
      
      loginfo(paste("QC report saved to:", output_file))
    }
    
    loginfo("QC report generation completed")
    return(qc_results)
    
  }, error = function(e) {
    logerror(paste("Error generating QC report:", e$message))
    return(NULL)
  })
}

create_qc_summary_report <- function(qc_results, output_file) {
  # Create a human-readable summary report
  summary_lines <- c(
    paste("GBIF Collections Registry - Quality Control Report"),
    paste("Generated:", qc_results$report_metadata$generated_at),
    paste("Database:", qc_results$report_metadata$database_name),
    "",
    paste("Overall Status:", qc_results$overall_status),
    "",
    "Check Results:",
    paste("- Completeness:", qc_results$completeness$overall_status),
    paste("- Consistency:", qc_results$consistency$overall_status),
    paste("- Validity:", qc_results$validity$overall_status),
    paste("- Business Rules:", qc_results$business_rules$overall_status)
  )
  
  writeLines(summary_lines, output_file)
}