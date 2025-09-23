# Toolkit del Registro de Colecciones GBIF España - Guía de Uso

Esta guía proporciona instrucciones comprehensivas para usar el Toolkit del Registro de Colecciones GBIF España para acceder, explorar, analizar el registro de colecciones.

## Descripción General

El Registro de Colecciones GBIF España (https://gbif.es/registro-colecciones/) es una base de datos privada de metadatos que cataloga las colecciones españolas de historia natural. Este toolkit proporciona acceso autorizado a la base de datos subyacente para operaciones de gestión de datos.

## Funcionalidades Principales

El toolkit proporciona tres operaciones principales:

1. **Exploración de Base de Datos** - Analizar estructura y contenido de base de datos
2. **Verificaciones de Control de Calidad** - Validar calidad e integridad de datos
3. **Análisis de Datos** - Generar perspectivas y tendencias de los datos

**NOTA IMPORTANTE**: Las funcionalidades de actualización están deshabilitadas en esta versión por seguridad.

## Patrones de Uso General

### Selección de Entorno

Siempre especifica el entorno objetivo:
- `TEST` - Para desarrollo y pruebas (seguro para experimentación)
- `PROD` - Para operaciones de producción (requiere precaución extra)

**Buena Práctica**: Siempre prueba operaciones en entorno `TEST` primero.

### Gestión de Salidas

Todas las operaciones generan salidas en el directorio `output/`:
- Los reportes tienen marca temporal para control de versiones
- Múltiples formatos disponibles (RDS, CSV, JSON)
- Los logs se mantienen en directorio `logs/`

## Exploración de Base de Datos

### Exploración Básica

Explorar toda la estructura y contenido de base de datos:

```bash
# Explorar base de datos TEST con reporte completo
Rscript scripts/run_exploration.R TEST

# Explorar base de datos PROD, guardar en directorio personalizado
Rscript scripts/run_exploration.R PROD reportes

# Exploración rápida sin reporte comprehensivo
Rscript scripts/run_exploration.R TEST output FALSE
```

### Understanding Exploration Output

The exploration generates:

1. **Schema Information**
   - Database size and table count
   - Table-by-table row counts and column information
   - Index and constraint details

2. **Data Summaries**
   - Statistical summaries for each table
   - Data type analysis
   - Completeness assessment

3. **Quality Metrics**
   - Empty row detection
   - Duplicate identification
   - Data consistency checks

### Example Exploration Workflow

```r
# Manual exploration using R
source("src/connection/db_connection.R")
source("src/exploration/data_exploration.R")

# Connect to TEST database
conn <- setup_database_connection("TEST")

# Get database overview
schema_info <- explore_database_schema(conn)
print(paste("Database contains", schema_info$table_count, "tables"))

# Explore specific table
collections_info <- explore_table_structure(conn, "collections")
collections_summary <- get_data_summary(conn, "collections", sample_size = 500)

# Close connection
close_database_connection(conn)
```

## Quality Control Checks

### Running All QC Checks

```bash
# Comprehensive quality control on TEST database
Rscript scripts/run_qc_checks.R TEST

# QC checks on PROD with custom output directory
Rscript scripts/run_qc_checks.R PROD quality_reports

# Run specific check types only
Rscript scripts/run_qc_checks.R TEST output completeness,consistency

# Skip report generation (faster execution)
Rscript scripts/run_qc_checks.R TEST output all FALSE
```

### Understanding QC Check Types

1. **Completeness Checks**
   - Verify required fields are populated
   - Calculate completeness percentages
   - Identify missing critical data

2. **Consistency Checks**
   - Validate referential integrity
   - Check date logic (created ≤ modified)
   - Verify identifier uniqueness

3. **Validity Checks**
   - Email format validation
   - URL format validation
   - Date format verification
   - Field length constraints

4. **Business Rules Checks**
   - Institution must have contacts
   - Collection must belong to active institution
   - Geographic coordinate validation
   - GBIF-specific requirements

### Interpreting QC Results

QC checks return status codes:
- `PASS` - All checks successful
- `WARNING` - Issues found but not critical
- `FAIL` - Critical issues requiring attention

### Example QC Workflow

```r
# Manual QC checks using R
source("src/connection/db_connection.R")
source("src/quality_control/qc_checks.R")

conn <- setup_database_connection("TEST")

# Run completeness checks only
completeness_results <- run_completeness_checks(conn)

# Check specific table completeness
if (!is.null(completeness_results$table_results$collections)) {
  collections_qc <- completeness_results$table_results$collections
  print(paste("Collections table has", collections_qc$total_rows, "rows"))
  
  # Review field completeness
  for (field in names(collections_qc$field_results)) {
    field_result <- collections_qc$field_results[[field]]
    if (field_result$completeness_rate < 90) {
      print(paste("Warning:", field, "only", field_result$completeness_rate, "% complete"))
    }
  }
}

close_database_connection(conn)
```

## Data Analysis

### Comprehensive Analysis

```bash
# Full analytics dashboard for TEST
Rscript scripts/run_analysis.R TEST

# Production analysis with custom settings
Rscript scripts/run_analysis.R PROD analytics dashboard rds,csv,json

# Specific analysis types only
Rscript scripts/run_analysis.R TEST results trends,coverage csv
```

### Analysis Types Available

1. **Collection Trends**
   - Creation and modification patterns over time
   - Activity levels and growth trends
   - Institutional distribution analysis

2. **Institutional Coverage**
   - Geographic distribution mapping
   - Institution size categories
   - Type-based analysis (if available)

3. **Data Patterns**
   - Naming convention analysis
   - Data entry timing patterns
   - Update frequency analysis

4. **Completeness Trends**
   - Field completeness over time
   - Data quality evolution
   - Improvement tracking

### Example Analysis Workflow

```r
# Custom analysis using R
source("src/connection/db_connection.R")
source("src/analysis/data_analysis.R")

conn <- setup_database_connection("PROD")

# Analyze collection trends
trends <- analyze_collection_trends(conn, time_period = "quarter")

# Review recent activity
if (!is.null(trends$activity_analysis)) {
  print("Collection Activity Levels:")
  for (i in 1:nrow(trends$activity_analysis)) {
    row <- trends$activity_analysis[i, ]
    print(paste("-", row$activity_level, ":", row$count, "collections"))
  }
}

# Generate comprehensive dashboard
dashboard <- generate_analytics_dashboard(conn)

# Export results
export_analysis_results(dashboard, "custom_analysis", c("rds", "csv"))

close_database_connection(conn)
```

## Database Updates

### Safety First: Always Test Before Production

```bash
# 1. Validate update data first
Rscript scripts/run_updates.R TEST validate collection_updates.csv

# 2. Test update on TEST environment
Rscript scripts/run_updates.R TEST update_collection test_collection.csv

# 3. Only then proceed to PROD (with confirmation prompt)
Rscript scripts/run_updates.R PROD update_collection collection_updates.csv
```

### Update Operations

1. **Single Collection Update**
   ```bash
   # Update one collection record
   Rscript scripts/run_updates.R TEST update_collection single_collection.csv TRUE
   ```

2. **Single Institution Update**
   ```bash
   # Update one institution record
   Rscript scripts/run_updates.R TEST update_institution single_institution.csv TRUE
   ```

3. **Bulk Updates**
   ```bash
   # Update multiple records (automatic backup)
   Rscript scripts/run_updates.R TEST bulk_update bulk_collections.csv TRUE
   ```

### Data File Formats

The toolkit supports multiple data formats:

#### CSV Format
```csv
key,name,description,institution_key
12345,Updated Collection Name,New description,67890
```

#### JSON Format
```json
{
  "key": "12345",
  "name": "Updated Collection Name",
  "description": "New description",
  "institution_key": "67890"
}
```

#### RDS Format (R Data)
```r
# Create update data in R
update_data <- data.frame(
  key = "12345",
  name = "Updated Collection Name",
  description = "New description",
  institution_key = "67890"
)

# Save as RDS
saveRDS(update_data, "collection_update.rds")
```

### Update Workflow Example

```r
# Manual update workflow using R
source("src/connection/db_connection.R")
source("src/updates/db_updates.R")

conn <- setup_database_connection("TEST")

# Prepare update data
update_data <- list(
  key = "existing-collection-key",
  name = "New Collection Name",
  description = "Updated description"
)

# Validate before updating
validation <- validate_update_data(conn, "collections", update_data)
if (validation$validation_passed) {
  print("Validation passed - proceeding with update")
  
  # Create backup
  backup_id <- backup_before_update(conn, "collections")
  
  # Perform update
  result <- update_collection_record(conn, update_data$key, update_data)
  
  if (result$success) {
    print("Update successful!")
    log_update_operations(conn, result)
  } else {
    print("Update failed - rolling back")
    rollback_updates(conn, backup_id)
  }
} else {
  print("Validation failed:")
  print(validation$errors)
}

close_database_connection(conn)
```

## Advanced Usage

### Combining Operations

Chain operations for comprehensive workflows:

```bash
# 1. Explore database
Rscript scripts/run_exploration.R TEST exploration_output

# 2. Run quality checks
Rscript scripts/run_qc_checks.R TEST qc_output

# 3. Analyze data
Rscript scripts/run_analysis.R TEST analysis_output dashboard

# 4. Apply updates (if needed)
Rscript scripts/run_updates.R TEST validate update_data.csv
```

### Custom R Scripts

Create custom scripts combining multiple modules:

```r
# custom_workflow.R
source("src/connection/db_connection.R")
source("src/exploration/data_exploration.R")
source("src/quality_control/qc_checks.R")
source("src/analysis/data_analysis.R")

# Your custom analysis workflow
conn <- setup_database_connection("TEST")

# Custom exploration
tables <- dbListTables(conn)
for (table in tables) {
  print(paste("Processing table:", table))
  
  # Get basic stats
  count_query <- paste("SELECT COUNT(*) as count FROM", table)
  row_count <- execute_safe_query(conn, count_query)$count
  print(paste("  Rows:", row_count))
  
  # Run quality checks if significant data
  if (row_count > 0) {
    quality <- explore_data_quality(conn, table)
    if (quality$empty_rows_percentage > 20) {
      print(paste("  WARNING: High empty row percentage:", quality$empty_rows_percentage, "%"))
    }
  }
}

close_database_connection(conn)
```

### Scheduling and Automation

Set up automated reporting using cron jobs:

```bash
# Add to crontab for daily QC checks
0 6 * * * cd /path/to/metages-toolkit && Rscript scripts/run_qc_checks.R PROD daily_qc

# Weekly comprehensive analysis
0 8 * * 1 cd /path/to/metages-toolkit && Rscript scripts/run_analysis.R PROD weekly_analysis dashboard

# Monthly exploration
0 9 1 * * cd /path/to/metages-toolkit && Rscript scripts/run_exploration.R PROD monthly_exploration
```

## Error Handling and Troubleshooting

### Common Issues

1. **Connection Errors**
   ```bash
   # Test connection manually
   Rscript -e "source('src/connection/db_connection.R'); conn <- setup_database_connection('TEST'); test_connection(conn)"
   ```

2. **Permission Errors**
   ```bash
   # Check file permissions
   ls -la config/
   chmod 600 config/test_config.R
   ```

3. **Memory Issues**
   ```bash
   # Reduce sample sizes for large datasets
   Rscript scripts/run_exploration.R TEST output FALSE
   ```

### Monitoring and Logs

Check operation logs for detailed information:

```bash
# View recent operations
tail -f logs/test_operations.log
tail -f logs/prod_operations.log

# Search for specific issues
grep -i "error" logs/*.log
grep -i "failed" logs/*.log
```

## Best Practices

### Development Workflow

1. **Always start with TEST environment**
2. **Validate data before updates**
3. **Create backups before significant changes**
4. **Monitor logs for errors**
5. **Test operations incrementally**

### Production Operations

1. **Require explicit confirmation for PROD updates**
2. **Schedule operations during low-usage periods**
3. **Implement monitoring and alerting**
4. **Maintain audit trail of all changes**
5. **Have rollback procedures ready**

### Data Management

1. **Regular quality assessments**
2. **Trend monitoring for early issue detection**
3. **Documented update procedures**
4. **Version control for significant changes**
5. **Regular backup verification**

---

For additional support, consult the setup guide (`docs/setup.md`) or contact the GBIF.ES technical team.