# Database Updates Module

This module provides functions for safely updating data in the GBIF Collections Registry database.

## Files:
- `db_updates.R`: Database update and modification functions

## Functions:
- `validate_update_data()`: Validate data before updates
- `update_collection_record()`: Update individual collection records
- `update_institution_record()`: Update individual institution records
- `bulk_update_records()`: Perform bulk updates with validation
- `backup_before_update()`: Create backup before major updates
- `rollback_updates()`: Rollback updates if needed
- `log_update_operations()`: Log all update operations

## Usage:
```r
# Load the updates module
source("src/updates/db_updates.R")

# Load connection module
source("src/connection/db_connection.R")

# Connect to database
conn <- setup_database_connection("TEST")  # Always test first!

# Validate data before update
validation_result <- validate_update_data(conn, update_data)

# Create backup
backup_id <- backup_before_update(conn, "collections")

# Perform update
update_result <- update_collection_record(conn, collection_id, new_data)

# Check results and rollback if needed
if (update_result$success) {
  log_update_operations(conn, update_result)
} else {
  rollback_updates(conn, backup_id)
}
```

## Safety Notes:
- Always test updates on TEST environment first
- Create backups before significant updates
- Validate all data before applying updates
- Log all operations for audit trail