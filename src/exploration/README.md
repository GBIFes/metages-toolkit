# Data Exploration Module

This module provides functions for exploring the GBIF Collections Registry database.

## Files:
- `data_exploration.R`: Functions for database exploration and data profiling

## Functions:
- `explore_database_schema()`: Get overview of database structure
- `explore_table_structure()`: Analyze specific table structure
- `get_data_summary()`: Generate data summaries and statistics
- `explore_data_quality()`: Basic data quality assessment
- `generate_exploration_report()`: Create comprehensive exploration report

## Usage:
```r
# Load the exploration module
source("src/exploration/data_exploration.R")

# Load connection module
source("src/connection/db_connection.R")

# Connect to database
conn <- setup_database_connection("TEST")

# Explore database schema
schema_info <- explore_database_schema(conn)

# Explore specific table
table_info <- explore_table_structure(conn, "collections")

# Generate summary statistics
summary_stats <- get_data_summary(conn, "collections")

# Generate full exploration report
report <- generate_exploration_report(conn)
```