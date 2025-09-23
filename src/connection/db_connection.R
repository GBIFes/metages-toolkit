# Database Connection Module for GBIF Collections Registry
# This module provides functions to connect to MySQL databases via SSH tunnel for PROD and TEST environments

# Load required libraries
library(DBI)
library(odbc)
library(ssh)
library(pool)
library(logging)

#' Setup Database Connection
#' 
#' Establishes a connection to the MySQL database via SSH tunnel based on the specified environment
#' 
#' @param environment Character. Either "PROD" or "TEST"
#' @param use_pool Logical. Whether to use connection pooling (default: TRUE)
#' @return List containing database connection object/pool and SSH session
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
  
  loginfo(paste("Attempting to connect to", environment, "database via SSH tunnel"))
  
  # Establish SSH tunnel
  ssh_session <- setup_ssh_tunnel(db_config)
  
  tryCatch({
    if (use_pool) {
      # Create connection pool for better performance
      connection <- dbPool(
        drv = odbc::odbc(),
        driver = db_config$odbc_driver,
        server = "127.0.0.1",  # Local endpoint of SSH tunnel
        port = db_config$local_port,
        dbname = db_config$database,
        uid = db_config$username,
        pwd = db_config$password,
        charset = db_config$charset,
        minSize = 1,
        maxSize = db_config$pool_size
      )
    } else {
      # Create single connection
      connection <- dbConnect(
        odbc::odbc(),
        driver = db_config$odbc_driver,
        server = "127.0.0.1",  # Local endpoint of SSH tunnel
        port = db_config$local_port,
        database = db_config$database,
        uid = db_config$username,
        pwd = db_config$password,
        charset = db_config$charset
      )
    }
    
    loginfo(paste("Successfully connected to", environment, "database via SSH tunnel"))
    
    # Test the connection
    if (test_connection(connection)) {
      return(list(
        connection = connection,
        ssh_session = ssh_session,
        environment = environment
      ))
    } else {
      stop("Connection test failed")
    }
    
  }, error = function(e) {
    logerror(paste("Failed to connect to", environment, "database:", e$message))
    
    # Clean up SSH session if connection failed
    if (!is.null(ssh_session)) {
      tryCatch({
        ssh::ssh_disconnect(ssh_session)
      }, error = function(ssh_err) {
        logwarn(paste("Error closing SSH session:", ssh_err$message))
      })
    }
    
    stop(e)
  })
}

#' Setup SSH Tunnel
#' 
#' Establishes an SSH tunnel to the database server
#' 
#' @param db_config List with database configuration
#' @return SSH session object
setup_ssh_tunnel <- function(db_config) {
  loginfo("Setting up SSH tunnel")
  
  tryCatch({
    # Create SSH connection
    ssh_session <- ssh::ssh_connect(
      host = paste0(db_config$ssh_user, "@", db_config$ssh_host, ":", db_config$ssh_port),
      keyfile = db_config$ssh_keyfile
    )
    
    # Create tunnel: local_port -> remote_host:remote_port
    ssh::ssh_tunnel(
      session = ssh_session,
      port = db_config$local_port,
      target = paste0(db_config$remote_host, ":", db_config$remote_port)
    )
    
    loginfo(paste("SSH tunnel established:", 
                  "localhost:", db_config$local_port, " -> ", 
                  db_config$remote_host, ":", db_config$remote_port))
    
    # Give tunnel time to establish
    Sys.sleep(2)
    
    return(ssh_session)
    
  }, error = function(e) {
    logerror(paste("Failed to setup SSH tunnel:", e$message))
    stop(e)
  })
}

#' Test Database Connection
#' 
#' Tests if the database connection is working properly
#' 
#' @param connection_obj Connection object or list with connection
#' @return Logical indicating if connection is working
#' @export
test_connection <- function(connection_obj) {
  # Extract connection from object if needed
  connection <- if (is.list(connection_obj) && "connection" %in% names(connection_obj)) {
    connection_obj$connection
  } else {
    connection_obj
  }
  
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
#' Safely closes database connection/pool and SSH tunnel
#' 
#' @param connection_obj Database connection object, pool, or list with connection and SSH session
#' @export
close_database_connection <- function(connection_obj) {
  tryCatch({
    # Handle different input types
    if (is.list(connection_obj) && "connection" %in% names(connection_obj)) {
      # New format with SSH session
      connection <- connection_obj$connection
      ssh_session <- connection_obj$ssh_session
      
      # Close database connection
      if (inherits(connection, "Pool")) {
        poolClose(connection)
        loginfo("Database connection pool closed")
      } else {
        dbDisconnect(connection)
        loginfo("Database connection closed")
      }
      
      # Close SSH tunnel
      if (!is.null(ssh_session)) {
        ssh::ssh_disconnect(ssh_session)
        loginfo("SSH tunnel closed")
      }
      
    } else {
      # Legacy format - just connection
      if (inherits(connection_obj, "Pool")) {
        poolClose(connection_obj)
        loginfo("Database connection pool closed")
      } else {
        dbDisconnect(connection_obj)
        loginfo("Database connection closed")
      }
    }
    
  }, error = function(e) {
    logwarn(paste("Error closing database connection:", e$message))
  })
}

#' Get Connection Information
#' 
#' Returns information about the current database connection
#' 
#' @param connection_obj Database connection object or list with connection
#' @return List with connection details
#' @export
get_connection_info <- function(connection_obj) {
  # Extract connection from object if needed
  connection <- if (is.list(connection_obj) && "connection" %in% names(connection_obj)) {
    connection_obj$connection
  } else {
    connection_obj
  }
  
  tryCatch({
    info <- dbGetInfo(connection)
    
    # Get database version and other info
    version_query <- dbGetQuery(connection, "SELECT VERSION() as version")
    current_db <- dbGetQuery(connection, "SELECT DATABASE() as current_database")
    
    result <- list(
      driver = "ODBC",
      server_version = version_query$version,
      current_database = current_db$current_database,
      connection_valid = dbIsValid(connection)
    )
    
    # Add SSH tunnel info if available
    if (is.list(connection_obj) && "ssh_session" %in% names(connection_obj)) {
      result$ssh_tunnel = "Active"
      result$environment = connection_obj$environment
    }
    
    return(result)
    
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
#' @param connection_obj Database connection object or list with connection
#' @param query SQL query string
#' @param params List of parameters for parameterized queries
#' @return Query result or NULL if error
#' @export
execute_safe_query <- function(connection_obj, query, params = NULL) {
  # Extract connection from object if needed
  connection <- if (is.list(connection_obj) && "connection" %in% names(connection_obj)) {
    connection_obj$connection
  } else {
    connection_obj
  }
  
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