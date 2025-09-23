# GBIF Collections Registry Toolkit - Setup Guide

This guide provides step-by-step instructions for setting up and configuring the GBIF Collections Registry Toolkit.

## Prerequisites

### Software Requirements

1. **R (version 4.0.0 or higher)**
   - Download from: https://www.r-project.org/
   - Verify installation: `R --version`

2. **Required R packages**
   ```r
   # Install required packages
   install.packages(c(
     "DBI",
     "RMySQL", 
     "pool",
     "dplyr",
     "ggplot2",
     "plotly",
     "lubridate",
     "tidyr",
     "scales",
     "stringr",
     "logging",
     "uuid",
     "jsonlite",
     "knitr"
   ))
   ```

3. **MySQL Database Access**
   - MySQL server with GBIF Collections Registry database
   - Valid credentials for both PROD and TEST environments
   - Network access to database servers

### System Requirements

- **Operating System**: Linux, macOS, or Windows
- **Memory**: Minimum 4GB RAM (8GB recommended for large datasets)
- **Storage**: At least 1GB free space for logs and temporary files
- **Network**: Stable connection to MySQL database servers

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/GBIFes/metages-toolkit.git
cd metages-toolkit
```

### 2. Install R Dependencies

Launch R and install required packages:

```r
# Run this in R console
source("setup_dependencies.R")  # If available, or install manually as shown above
```

### 3. Configure Database Connections

#### Production Environment

1. Copy the production configuration template:
   ```bash
   cp config/prod_config.R.template config/prod_config.R
   ```

2. Edit `config/prod_config.R` with your production database credentials:
   ```r
   # Edit these values with your actual production database details
   DB_CONFIG_PROD <- list(
     host = "prod-mysql.your-domain.com",
     port = 3306,
     database = "gbif_collections_prod",
     username = "your_prod_username",
     password = "your_prod_password",
     # ... other settings
   )
   ```

#### Test Environment

1. Copy the test configuration template:
   ```bash
   cp config/test_config.R.template config/test_config.R
   ```

2. Edit `config/test_config.R` with your test database credentials:
   ```r
   # Edit these values with your actual test database details
   DB_CONFIG_TEST <- list(
     host = "test-mysql.your-domain.com",
     port = 3306,
     database = "gbif_collections_test",
     username = "your_test_username",
     password = "your_test_password",
     # ... other settings
   )
   ```

### 4. Create Required Directories

```bash
# Create output and log directories
mkdir -p output logs plots
```

### 5. Test Database Connections

Test your configuration by running a simple connection test:

```r
# Test production connection
source("src/connection/db_connection.R")
prod_conn <- setup_database_connection("PROD")
test_connection(prod_conn)
close_database_connection(prod_conn)

# Test development connection
test_conn <- setup_database_connection("TEST")
test_connection(test_conn)
close_database_connection(test_conn)
```

## Configuration Details

### Database Configuration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `host` | MySQL server hostname | Yes | - |
| `port` | MySQL server port | Yes | 3306 |
| `database` | Database name | Yes | - |
| `username` | Database username | Yes | - |
| `password` | Database password | Yes | - |
| `charset` | Character encoding | No | utf8mb4 |
| `timeout` | Connection timeout (seconds) | No | 30 |
| `pool_size` | Connection pool size | No | 5 (PROD), 3 (TEST) |

### SSL Configuration (Optional)

If your MySQL server requires SSL connections:

```r
DB_CONFIG_PROD <- list(
  # ... other settings ...
  ssl_cert = "/path/to/client-cert.pem",
  ssl_key = "/path/to/client-key.pem",
  ssl_ca = "/path/to/ca-cert.pem"
)
```

### Logging Configuration

Adjust logging levels and file locations in the configuration files:

```r
# Logging settings
LOG_LEVEL <- "INFO"  # Options: DEBUG, INFO, WARN, ERROR
LOG_FILE <- "logs/prod_operations.log"
```

## Environment Variables (Alternative Configuration)

For enhanced security, you can use environment variables instead of storing credentials in files:

1. Set environment variables:
   ```bash
   export GBIF_PROD_HOST="prod-mysql.your-domain.com"
   export GBIF_PROD_USER="your_prod_username"
   export GBIF_PROD_PASSWORD="your_prod_password"
   export GBIF_PROD_DATABASE="gbif_collections_prod"
   
   export GBIF_TEST_HOST="test-mysql.your-domain.com"
   export GBIF_TEST_USER="your_test_username"
   export GBIF_TEST_PASSWORD="your_test_password"
   export GBIF_TEST_DATABASE="gbif_collections_test"
   ```

2. Modify configuration files to use environment variables:
   ```r
   DB_CONFIG_PROD <- list(
     host = Sys.getenv("GBIF_PROD_HOST"),
     port = 3306,
     database = Sys.getenv("GBIF_PROD_DATABASE"),
     username = Sys.getenv("GBIF_PROD_USER"),
     password = Sys.getenv("GBIF_PROD_PASSWORD"),
     # ... other settings
   )
   ```

## Security Considerations

### File Permissions

Restrict access to configuration files containing credentials:

```bash
chmod 600 config/prod_config.R
chmod 600 config/test_config.R
```

### Git Configuration

Ensure credentials are never committed to version control:

1. Configuration files are already in `.gitignore`
2. Verify with: `git status` (should not show config files)
3. If accidentally added: `git rm --cached config/prod_config.R`

### Network Security

- Use SSL/TLS connections when possible
- Restrict database access to specific IP addresses
- Use VPN for remote database connections
- Regularly rotate database passwords

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check database server hostname and port
   - Verify network connectivity: `telnet hostname port`
   - Check firewall settings

2. **Authentication Failed**
   - Verify username and password
   - Check user permissions in MySQL
   - Ensure user has access from your IP address

3. **SSL Certificate Errors**
   - Verify SSL certificate paths
   - Check certificate validity
   - Test SSL connection manually

4. **Permission Denied on Log Files**
   - Check directory permissions: `ls -la logs/`
   - Create directory if missing: `mkdir -p logs`
   - Adjust permissions: `chmod 755 logs`

### Testing Commands

```bash
# Test database connection
Rscript -e "source('src/connection/db_connection.R'); conn <- setup_database_connection('TEST'); print(test_connection(conn)); close_database_connection(conn)"

# Test specific script
Rscript scripts/run_exploration.R TEST output FALSE

# Check R package installation
Rscript -e "packageVersion('DBI')"
```

### Log Analysis

Check log files for detailed error information:

```bash
# View recent log entries
tail -f logs/test_operations.log
tail -f logs/prod_operations.log

# Search for errors
grep -i error logs/*.log
grep -i warning logs/*.log
```

## Next Steps

After successful setup:

1. **Read the Usage Guide**: `docs/usage.md`
2. **Run initial exploration**: `Rscript scripts/run_exploration.R TEST`
3. **Perform quality checks**: `Rscript scripts/run_qc_checks.R TEST`
4. **Review generated reports** in the `output/` directory

## Support

For technical support or questions:

1. Check the repository documentation
2. Review log files for error details
3. Contact the GBIF.ES technical team
4. Open an issue in the GitHub repository (for non-sensitive issues)

---

**Important**: Always test operations on the TEST environment before running on PRODUCTION data.