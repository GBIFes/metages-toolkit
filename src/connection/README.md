# Database Connection Module

This module handles database connections for both PROD and TEST environments.

## Files:
- `db_connection.R`: Main database connection functions

## Functions:
- `setup_database_connection()`: Establishes connection based on environment
- `close_database_connection()`: Safely closes database connections
- `test_connection()`: Tests database connectivity
- `get_connection_info()`: Returns connection status information

## Usage:
```r
# Load the connection module
source("src/connection/db_connection.R")

# Connect to production database
prod_conn <- setup_database_connection("PROD")

# Connect to test database  
test_conn <- setup_database_connection("TEST")

# Test connection
test_connection(prod_conn)

# Close connection when done
close_database_connection(prod_conn)
```