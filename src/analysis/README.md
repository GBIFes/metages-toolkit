# Data Analysis Module

This module provides functions for analyzing data in the GBIF Collections Registry database.

## Files:
- `data_analysis.R`: Analysis functions for collections and institutions data

## Functions:
- `analyze_collection_trends()`: Analyze trends in collection data over time
- `analyze_institutional_coverage()`: Analyze geographic and taxonomic coverage
- `analyze_data_patterns()`: Identify patterns and anomalies in the data
- `analyze_completeness_trends()`: Track data completeness over time
- `generate_analytics_dashboard()`: Create summary analytics
- `export_analysis_results()`: Export analysis results to various formats

## Usage:
```r
# Load the analysis module
source("src/analysis/data_analysis.R")

# Load connection module
source("src/connection/db_connection.R")

# Connect to database
conn <- setup_database_connection("PROD")

# Run specific analyses
trends <- analyze_collection_trends(conn)
coverage <- analyze_institutional_coverage(conn)

# Generate comprehensive analytics
dashboard <- generate_analytics_dashboard(conn)

# Export results
export_analysis_results(dashboard, "analytics_report")
```