# Data Analysis Module for GBIF Collections Registry
# This module provides comprehensive analysis functions for collections and institutions data

# Load required libraries
library(DBI)
library(dplyr)
library(ggplot2)
library(plotly)
library(lubridate)
library(tidyr)
library(scales)
library(logging)

#' Analyze Collection Trends
#' 
#' Analyzes trends in collection data over time
#' 
#' @param connection Database connection object
#' @param time_period Character. Time period for analysis ("month", "quarter", "year")
#' @return List with trend analysis results
#' @export
analyze_collection_trends <- function(connection, time_period = "month") {
  loginfo("Starting collection trends analysis")
  
  tryCatch({
    trends_results <- list()
    trends_results$timestamp <- Sys.time()
    trends_results$analysis_type <- "collection_trends"
    trends_results$time_period <- time_period
    
    # Check if collections table exists
    if (!"collections" %in% dbListTables(connection)) {
      logwarn("Collections table not found")
      return(NULL)
    }
    
    # Get date format based on time period
    date_format <- switch(time_period,
      "month" = "%Y-%m",
      "quarter" = "%Y-Q%q",
      "year" = "%Y",
      "%Y-%m"
    )
    
    # Collection creation trends
    creation_trends_query <- paste(
      "SELECT DATE_FORMAT(created, '", date_format, "') as time_period,",
      "COUNT(*) as collections_created",
      "FROM collections",
      "WHERE created IS NOT NULL",
      "GROUP BY DATE_FORMAT(created, '", date_format, "')",
      "ORDER BY time_period"
    )
    
    creation_trends <- execute_safe_query(connection, creation_trends_query)
    trends_results$creation_trends <- creation_trends
    
    # Collection modification trends
    modification_trends_query <- paste(
      "SELECT DATE_FORMAT(modified, '", date_format, "') as time_period,",
      "COUNT(*) as collections_modified",
      "FROM collections",
      "WHERE modified IS NOT NULL",
      "GROUP BY DATE_FORMAT(modified, '", date_format, "')",
      "ORDER BY time_period"
    )
    
    modification_trends <- execute_safe_query(connection, modification_trends_query)
    trends_results$modification_trends <- modification_trends
    
    # Collections by institution trends
    institutional_trends_query <- paste(
      "SELECT i.name as institution_name,",
      "COUNT(c.key) as collection_count,",
      "MIN(c.created) as first_collection,",
      "MAX(c.created) as latest_collection",
      "FROM collections c",
      "JOIN institutions i ON c.institution_key = i.key",
      "GROUP BY i.key, i.name",
      "ORDER BY collection_count DESC",
      "LIMIT 20"
    )
    
    institutional_trends <- execute_safe_query(connection, institutional_trends_query)
    trends_results$institutional_trends <- institutional_trends
    
    # Active vs inactive collections
    activity_query <- "
      SELECT 
        CASE 
          WHEN modified > DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 'Active (< 1 year)'
          WHEN modified > DATE_SUB(NOW(), INTERVAL 2 YEAR) THEN 'Moderate (1-2 years)'
          ELSE 'Inactive (> 2 years)'
        END as activity_level,
        COUNT(*) as count
      FROM collections 
      WHERE modified IS NOT NULL
      GROUP BY activity_level"
    
    activity_analysis <- execute_safe_query(connection, activity_query)
    trends_results$activity_analysis <- activity_analysis
    
    loginfo("Collection trends analysis completed")
    return(trends_results)
    
  }, error = function(e) {
    logerror(paste("Error in collection trends analysis:", e$message))
    return(NULL)
  })
}

#' Analyze Institutional Coverage
#' 
#' Analyzes geographic and taxonomic coverage of institutions
#' 
#' @param connection Database connection object
#' @return List with coverage analysis results
#' @export
analyze_institutional_coverage <- function(connection) {
  loginfo("Starting institutional coverage analysis")
  
  tryCatch({
    coverage_results <- list()
    coverage_results$timestamp <- Sys.time()
    coverage_results$analysis_type <- "institutional_coverage"
    
    # Check required tables
    required_tables <- c("institutions", "collections")
    missing_tables <- required_tables[!required_tables %in% dbListTables(connection)]
    
    if (length(missing_tables) > 0) {
      logwarn(paste("Missing required tables:", paste(missing_tables, collapse = ", ")))
      return(NULL)
    }
    
    # Geographic distribution of institutions
    geographic_query <- "
      SELECT 
        country,
        COUNT(*) as institution_count,
        COUNT(DISTINCT c.key) as collection_count
      FROM institutions i
      LEFT JOIN collections c ON i.key = c.institution_key
      WHERE i.country IS NOT NULL
      GROUP BY country
      ORDER BY institution_count DESC"
    
    geographic_coverage <- execute_safe_query(connection, geographic_query)
    coverage_results$geographic_coverage <- geographic_coverage
    
    # Institution size distribution
    size_distribution_query <- "
      SELECT 
        CASE 
          WHEN collection_count = 0 THEN 'No collections'
          WHEN collection_count BETWEEN 1 AND 5 THEN 'Small (1-5)'
          WHEN collection_count BETWEEN 6 AND 20 THEN 'Medium (6-20)'
          WHEN collection_count BETWEEN 21 AND 50 THEN 'Large (21-50)'
          ELSE 'Very Large (>50)'
        END as size_category,
        COUNT(*) as institution_count
      FROM (
        SELECT i.key, COUNT(c.key) as collection_count
        FROM institutions i
        LEFT JOIN collections c ON i.key = c.institution_key
        GROUP BY i.key
      ) as inst_sizes
      GROUP BY size_category
      ORDER BY 
        CASE 
          WHEN size_category = 'No collections' THEN 1
          WHEN size_category = 'Small (1-5)' THEN 2
          WHEN size_category = 'Medium (6-20)' THEN 3
          WHEN size_category = 'Large (21-50)' THEN 4
          ELSE 5
        END"
    
    size_distribution <- execute_safe_query(connection, size_distribution_query)
    coverage_results$size_distribution <- size_distribution
    
    # Institution types analysis (if type field exists)
    columns <- dbListFields(connection, "institutions")
    if ("type" %in% columns) {
      type_analysis_query <- "
        SELECT 
          type,
          COUNT(*) as institution_count,
          COUNT(DISTINCT c.key) as collection_count
        FROM institutions i
        LEFT JOIN collections c ON i.key = c.institution_key
        WHERE type IS NOT NULL
        GROUP BY type
        ORDER BY institution_count DESC"
      
      type_analysis <- execute_safe_query(connection, type_analysis_query)
      coverage_results$type_analysis <- type_analysis
    }
    
    # Collections per institution statistics
    collections_stats_query <- "
      SELECT 
        MIN(collection_count) as min_collections,
        MAX(collection_count) as max_collections,
        AVG(collection_count) as avg_collections,
        STDDEV(collection_count) as std_collections
      FROM (
        SELECT COUNT(c.key) as collection_count
        FROM institutions i
        LEFT JOIN collections c ON i.key = c.institution_key
        GROUP BY i.key
      ) as stats"
    
    collections_stats <- execute_safe_query(connection, collections_stats_query)
    coverage_results$collections_statistics <- collections_stats
    
    loginfo("Institutional coverage analysis completed")
    return(coverage_results)
    
  }, error = function(e) {
    logerror(paste("Error in institutional coverage analysis:", e$message))
    return(NULL)
  })
}

#' Analyze Data Patterns
#' 
#' Identifies patterns and anomalies in the data
#' 
#' @param connection Database connection object
#' @return List with pattern analysis results
#' @export
analyze_data_patterns <- function(connection) {
  loginfo("Starting data patterns analysis")
  
  tryCatch({
    patterns_results <- list()
    patterns_results$timestamp <- Sys.time()
    patterns_results$analysis_type <- "data_patterns"
    
    # Naming patterns analysis
    patterns_results$naming_patterns <- analyze_naming_patterns(connection)
    
    # Data entry patterns
    patterns_results$entry_patterns <- analyze_entry_patterns(connection)
    
    # Update frequency patterns
    patterns_results$update_patterns <- analyze_update_patterns(connection)
    
    # Identifier patterns
    patterns_results$identifier_patterns <- analyze_identifier_patterns(connection)
    
    loginfo("Data patterns analysis completed")
    return(patterns_results)
    
  }, error = function(e) {
    logerror(paste("Error in data patterns analysis:", e$message))
    return(NULL)
  })
}

#' Analyze Completeness Trends
#' 
#' Tracks data completeness over time
#' 
#' @param connection Database connection object
#' @return List with completeness trend results
#' @export
analyze_completeness_trends <- function(connection) {
  loginfo("Starting completeness trends analysis")
  
  tryCatch({
    completeness_results <- list()
    completeness_results$timestamp <- Sys.time()
    completeness_results$analysis_type <- "completeness_trends"
    
    tables <- dbListTables(connection)
    
    for (table in tables) {
      loginfo(paste("Analyzing completeness trends for table:", table))
      
      # Get columns for the table
      columns <- dbListFields(connection, table)
      
      # Analyze completeness by creation date (if available)
      if ("created" %in% columns) {
        completeness_query <- paste(
          "SELECT ",
          "DATE_FORMAT(created, '%Y-%m') as month,",
          paste(sapply(columns, function(col) {
            paste("ROUND(COUNT(CASE WHEN", col, "IS NOT NULL AND", col, "!= '' THEN 1 END) / COUNT(*) * 100, 2) as", paste0(col, "_completeness"))
          }), collapse = ","),
          "FROM", table,
          "WHERE created IS NOT NULL",
          "GROUP BY DATE_FORMAT(created, '%Y-%m')",
          "ORDER BY month"
        )
        
        completeness_trends <- execute_safe_query(connection, completeness_query)
        completeness_results[[paste0(table, "_trends")]] <- completeness_trends
      }
      
      # Overall completeness for the table
      overall_completeness_query <- paste(
        "SELECT",
        paste(sapply(columns, function(col) {
          paste("ROUND(COUNT(CASE WHEN", col, "IS NOT NULL AND", col, "!= '' THEN 1 END) / COUNT(*) * 100, 2) as", paste0(col, "_completeness"))
        }), collapse = ","),
        "FROM", table
      )
      
      overall_completeness <- execute_safe_query(connection, overall_completeness_query)
      completeness_results[[paste0(table, "_overall")]] <- overall_completeness
    }
    
    loginfo("Completeness trends analysis completed")
    return(completeness_results)
    
  }, error = function(e) {
    logerror(paste("Error in completeness trends analysis:", e$message))
    return(NULL)
  })
}

#' Generate Analytics Dashboard
#' 
#' Creates a comprehensive analytics dashboard
#' 
#' @param connection Database connection object
#' @return List with dashboard data
#' @export
generate_analytics_dashboard <- function(connection) {
  loginfo("Generating analytics dashboard")
  
  tryCatch({
    dashboard <- list()
    dashboard$timestamp <- Sys.time()
    dashboard$analysis_type <- "comprehensive_dashboard"
    
    # Summary statistics
    dashboard$summary_stats <- generate_summary_statistics(connection)
    
    # Trend analyses
    dashboard$collection_trends <- analyze_collection_trends(connection)
    dashboard$institutional_coverage <- analyze_institutional_coverage(connection)
    dashboard$data_patterns <- analyze_data_patterns(connection)
    dashboard$completeness_trends <- analyze_completeness_trends(connection)
    
    # Key performance indicators
    dashboard$kpis <- calculate_kpis(connection)
    
    # Data health score
    dashboard$health_score <- calculate_data_health_score(dashboard)
    
    loginfo("Analytics dashboard generation completed")
    return(dashboard)
    
  }, error = function(e) {
    logerror(paste("Error generating analytics dashboard:", e$message))
    return(NULL)
  })
}

# Helper functions

analyze_naming_patterns <- function(connection) {
  # Analyze naming patterns in institution and collection names
  results <- list()
  
  tables_with_names <- c("institutions", "collections")
  
  for (table in tables_with_names) {
    if (table %in% dbListTables(connection)) {
      # Name length distribution
      length_query <- paste(
        "SELECT",
        "CASE",
        "  WHEN LENGTH(name) < 20 THEN 'Short (<20)'",
        "  WHEN LENGTH(name) BETWEEN 20 AND 50 THEN 'Medium (20-50)'",
        "  WHEN LENGTH(name) BETWEEN 51 AND 100 THEN 'Long (51-100)'",
        "  ELSE 'Very Long (>100)'",
        "END as name_length_category,",
        "COUNT(*) as count",
        "FROM", table,
        "WHERE name IS NOT NULL",
        "GROUP BY name_length_category"
      )
      
      length_dist <- execute_safe_query(connection, length_query)
      results[[paste0(table, "_name_lengths")]] <- length_dist
    }
  }
  
  return(results)
}

analyze_entry_patterns <- function(connection) {
  # Analyze data entry patterns
  results <- list()
  
  # Day of week patterns for data creation
  if ("collections" %in% dbListTables(connection)) {
    dow_query <- "
      SELECT 
        DAYNAME(created) as day_of_week,
        COUNT(*) as entries_count
      FROM collections 
      WHERE created IS NOT NULL
      GROUP BY DAYNAME(created), DAYOFWEEK(created)
      ORDER BY DAYOFWEEK(created)"
    
    dow_patterns <- execute_safe_query(connection, dow_query)
    results$day_of_week_patterns <- dow_patterns
  }
  
  return(results)
}

analyze_update_patterns <- function(connection) {
  # Analyze update frequency patterns
  results <- list()
  
  if ("collections" %in% dbListTables(connection)) {
    update_freq_query <- "
      SELECT 
        CASE 
          WHEN DATEDIFF(modified, created) = 0 THEN 'Same day'
          WHEN DATEDIFF(modified, created) <= 7 THEN 'Within week'
          WHEN DATEDIFF(modified, created) <= 30 THEN 'Within month'
          WHEN DATEDIFF(modified, created) <= 365 THEN 'Within year'
          ELSE 'Over a year'
        END as update_timeframe,
        COUNT(*) as count
      FROM collections 
      WHERE created IS NOT NULL AND modified IS NOT NULL
      GROUP BY update_timeframe"
    
    update_patterns <- execute_safe_query(connection, update_freq_query)
    results$update_frequency_patterns <- update_patterns
  }
  
  return(results)
}

generate_summary_statistics <- function(connection) {
  summary_stats <- list()
  
  tables <- dbListTables(connection)
  
  for (table in tables) {
    table_stats <- list()
    
    # Row count
    count_query <- paste("SELECT COUNT(*) as total_rows FROM", table)
    total_rows <- execute_safe_query(connection, count_query)$total_rows
    table_stats$total_rows <- total_rows
    
    # Creation date range (if applicable)
    columns <- dbListFields(connection, table)
    if ("created" %in% columns) {
      date_range_query <- paste(
        "SELECT MIN(created) as earliest, MAX(created) as latest FROM", table,
        "WHERE created IS NOT NULL"
      )
      date_range <- execute_safe_query(connection, date_range_query)
      table_stats$date_range <- date_range
    }
    
    summary_stats[[table]] <- table_stats
  }
  
  return(summary_stats)
}

calculate_kpis <- function(connection) {
  kpis <- list()
  
  # Total institutions and collections
  if ("institutions" %in% dbListTables(connection)) {
    inst_count <- execute_safe_query(connection, "SELECT COUNT(*) as count FROM institutions")$count
    kpis$total_institutions <- inst_count
  }
  
  if ("collections" %in% dbListTables(connection)) {
    coll_count <- execute_safe_query(connection, "SELECT COUNT(*) as count FROM collections")$count
    kpis$total_collections <- coll_count
  }
  
  # Growth rate (collections added in last 30 days)
  if ("collections" %in% dbListTables(connection)) {
    recent_query <- "SELECT COUNT(*) as recent_collections FROM collections WHERE created > DATE_SUB(NOW(), INTERVAL 30 DAY)"
    recent_count <- execute_safe_query(connection, recent_query)$recent_collections
    kpis$recent_collections_30_days <- recent_count
  }
  
  return(kpis)
}

calculate_data_health_score <- function(dashboard) {
  # Calculate a simple data health score based on completeness and activity
  health_components <- list()
  
  # Completeness score (average completeness across tables)
  if (!is.null(dashboard$completeness_trends)) {
    # This would need to be implemented based on actual completeness data
    health_components$completeness_score <- 85  # Placeholder
  }
  
  # Activity score (based on recent modifications)
  if (!is.null(dashboard$collection_trends$activity_analysis)) {
    # Calculate based on active vs inactive collections
    health_components$activity_score <- 75  # Placeholder
  }
  
  # Overall health score (average of components)
  health_score <- mean(unlist(health_components), na.rm = TRUE)
  
  return(list(
    overall_score = round(health_score, 1),
    components = health_components,
    rating = case_when(
      health_score >= 90 ~ "Excellent",
      health_score >= 80 ~ "Good",
      health_score >= 70 ~ "Fair",
      TRUE ~ "Needs Improvement"
    )
  ))
}

#' Export Analysis Results
#' 
#' Exports analysis results to various formats
#' 
#' @param analysis_results List with analysis results
#' @param output_prefix Character. Prefix for output files
#' @param formats Vector. Output formats ("rds", "csv", "json")
#' @export
export_analysis_results <- function(analysis_results, output_prefix, formats = c("rds", "csv")) {
  loginfo("Exporting analysis results")
  
  tryCatch({
    # Create output directory if it doesn't exist
    output_dir <- "output"
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    
    if ("rds" %in% formats) {
      rds_file <- file.path(output_dir, paste0(output_prefix, "_", timestamp, ".rds"))
      saveRDS(analysis_results, rds_file)
      loginfo(paste("Analysis results saved to:", rds_file))
    }
    
    if ("csv" %in% formats) {
      # Export data frames as CSV files
      export_dataframes_to_csv(analysis_results, output_dir, output_prefix, timestamp)
    }
    
    if ("json" %in% formats) {
      json_file <- file.path(output_dir, paste0(output_prefix, "_", timestamp, ".json"))
      jsonlite::write_json(analysis_results, json_file, pretty = TRUE)
      loginfo(paste("Analysis results saved to:", json_file))
    }
    
    loginfo("Analysis results export completed")
    
  }, error = function(e) {
    logerror(paste("Error exporting analysis results:", e$message))
  })
}

export_dataframes_to_csv <- function(data, output_dir, prefix, timestamp) {
  # Recursively find and export data frames
  export_recursive <- function(obj, path_prefix) {
    if (is.data.frame(obj)) {
      csv_file <- file.path(output_dir, paste0(prefix, "_", path_prefix, "_", timestamp, ".csv"))
      write.csv(obj, csv_file, row.names = FALSE)
      loginfo(paste("Data frame exported to:", csv_file))
    } else if (is.list(obj)) {
      for (name in names(obj)) {
        new_prefix <- if (path_prefix == "") name else paste(path_prefix, name, sep = "_")
        export_recursive(obj[[name]], new_prefix)
      }
    }
  }
  
  export_recursive(data, "")
}