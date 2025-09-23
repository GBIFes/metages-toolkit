# Database Connection Module for GBIF Collections Registry
# This module provides functions to connect to MySQL databases for PROD and TEST environments

# Load required libraries
library(DBI)
library(RMySQL)
library(pool)
library(logging)

#' Setup Database Connection
#' 
#' Establishes a connection to the MySQL database based on the specified environment
#' 
#' @param environment Character. Either "PROD" or "TEST"
#' @param use_pool Logical. Whether to use connection pooling (default: TRUE)
#' @return Database connection object or pool
#' @export
setup_database_connection <- function(environment = "PROD", use_pool = TRUE) {
  
  # Validate environment parameter
  if (!environment %in% c("PROD", "TEST")) {
    stop("Environment must be either 'PROD' or 'TEST'")
  }
  
  # Load appropriate configuration
  config_file <- paste0("config/", tolower(environment), "_config.R")
  
  if (!file.exists(config_file)) {
    stop(paste("Configuration file not found:", config_file, 
               "\nPlease copy the template and configure your credentials."))
  }
  
  source(config_file)
  
  # Get config based on environment
  db_config <- if (environment == "PROD") DB_CONFIG_PROD else DB_CONFIG_TEST
  
  # Setup logging
  setup_logging(db_config)
  
  loginfo(paste("Attempting to connect to", environment, "database"))
  
  tryCatch({
    if (use_pool) {
      # Create connection pool for better performance
      connection <- dbPool(
        drv = RMySQL::MySQL(),
        host = db_config$host,
        port = db_config$port,
        dbname = db_config$database,
        username = db_config$username,
        password = db_config$password,
        charset = db_config$charset,
        minSize = 1,
        maxSize = db_config$pool_size
      )
    } else {
      # Create single connection
      connection <- dbConnect(
        RMySQL::MySQL(),
        host = db_config$host,
        port = db_config$port,
        dbname = db_config$database,
        username = db_config$username,
        password = db_config$password,
        charset = db_config$charset
      )
    }
    
    loginfo(paste("Successfully connected to", environment, "database"))
    
    # Test the connection
    if (test_connection(connection)) {
      return(connection)
    } else {
      stop("Connection test failed")
    }
    
  }, error = function(e) {
    logerror(paste("Failed to connect to", environment, "database:", e$message))
    stop(e)
  })
}

#' Test Database Connection
#' 
#' Tests if the database connection is working properly
#' 
#' @param connection Database connection object
#' @return Logical indicating if connection is working
#' @export
test_connection <- function(connection) {
  tryCatch({
    # Simple query to test connection
    result <- dbGetQuery(connection, "SELECT 1 as test")
    
    if (nrow(result) == 1 && result$test == 1) {
      loginfo("Database connection test successful")
      return(TRUE)
    } else {
      logwarn("Database connection test returned unexpected result")
      return(FALSE)
    }
    
  }, error = function(e) {
    logerror(paste("Database connection test failed:", e$message))
    return(FALSE)
  })
}

#' Close Database Connection
#' 
#' Safely closes database connection or pool
#' 
#' @param connection Database connection object or pool
#' @export
close_database_connection <- function(connection) {
  tryCatch({
    if (inherits(connection, "Pool")) {
      poolClose(connection)
      loginfo("Database connection pool closed")
    } else {
      dbDisconnect(connection)
      loginfo("Database connection closed")
    }
  }, error = function(e) {
    logwarn(paste("Error closing database connection:", e$message))
  })
}

#' Get Connection Information
#' 
#' Returns information about the current database connection
#' 
#' @param connection Database connection object
#' @return List with connection details
#' @export
get_connection_info <- function(connection) {
  tryCatch({
    info <- dbGetInfo(connection)
    
    # Get database version and other info
    version_query <- dbGetQuery(connection, "SELECT VERSION() as version")
    current_db <- dbGetQuery(connection, "SELECT DATABASE() as current_database")
    
    return(list(
      driver = info$rsId,
      server_version = version_query$version,
      current_database = current_db$current_database,
      connection_valid = dbIsValid(connection)
    ))
    
  }, error = function(e) {
    logwarn(paste("Could not retrieve connection info:", e$message))
    return(NULL)
  })
}

#' Setup Logging
#' 
#' Configures logging for database operations
#' 
#' @param config Database configuration list
setup_logging <- function(config) {
  # Create logs directory if it doesn't exist
  log_dir <- dirname(config$LOG_FILE)
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE)
  }
  
  # Setup logging configuration
  basicConfig(level = config$LOG_LEVEL)
  addHandler(writeToFile, file = config$LOG_FILE)
}

#' Execute Safe Query
#' 
#' Executes a query with proper error handling and logging
#' 
#' @param connection Database connection
#' @param query SQL query string
#' @param params List of parameters for parameterized queries
#' @return Query result or NULL if error
#' @export
execute_safe_query <- function(connection, query, params = NULL) {
  tryCatch({
    logdebug(paste("Executing query:", query))
    
    if (is.null(params)) {
      result <- dbGetQuery(connection, query)
    } else {
      result <- dbGetQuery(connection, query, params = params)
    }
    
    logdebug(paste("Query executed successfully, returned", nrow(result), "rows"))
    return(result)
    
  }, error = function(e) {
    logerror(paste("Query execution failed:", e$message))
    logerror(paste("Query:", query))
    return(NULL)
  })
}