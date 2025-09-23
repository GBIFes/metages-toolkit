# Quality Control Module

This module provides functions for implementing quality control checks on the GBIF Collections Registry database.

## Files:
- `qc_checks.R`: Quality control check functions

## Functions:
- `run_completeness_checks()`: Check data completeness across tables
- `run_consistency_checks()`: Check data consistency and referential integrity
- `run_validity_checks()`: Validate data formats and constraints
- `run_business_rule_checks()`: Apply GBIF-specific business rules
- `run_all_qc_checks()`: Execute all quality control checks
- `generate_qc_report()`: Generate comprehensive QC report

## Usage:
```r
# Load the QC module
source("src/quality_control/qc_checks.R")

# Load connection module
source("src/connection/db_connection.R")

# Connect to database
conn <- setup_database_connection("TEST")

# Run specific checks
completeness_results <- run_completeness_checks(conn)
consistency_results <- run_consistency_checks(conn)

# Run all checks
all_results <- run_all_qc_checks(conn)

# Generate QC report
qc_report <- generate_qc_report(conn, "qc_report.html")
```