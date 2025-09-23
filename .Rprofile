# .Rprofile for GBIF Collections Registry Toolkit
# This file is automatically loaded when R starts in this project directory

# Display welcome message
cat("========================================\n")
cat("GBIF Collections Registry Toolkit\n")
cat("========================================\n")

# Set R options for better development experience
options(
  # General options
  width = 120,
  max.print = 1000,
  scipen = 999,  # Avoid scientific notation
  digits = 4,
  
  # Development options
  error = traceback,
  warn = 1,  # Show warnings as they occur
  
  # Database options
  timeout = 60,  # Default timeout for operations
  encoding = "UTF-8",
  
  # Output options
  stringsAsFactors = FALSE  # Default for older R versions
)

# Set timezone (adjust based on organizational needs)
Sys.setenv(TZ = "Europe/Madrid")

# Check for and activate renv if available
if (file.exists("renv.lock") && requireNamespace("renv", quietly = TRUE)) {
  cat("Activating renv environment...\n")
  renv::activate()
}

# Function to check required packages
check_required_packages <- function() {
  required_packages <- c(
    "DBI",
    "odbc",     # Changed from RMySQL to odbc
    "ssh",      # Added for SSH tunneling
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
  )
  
  missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
  
  if (length(missing_packages) > 0) {
    cat("⚠ WARNING: Missing required packages:\n")
    cat(paste("  -", missing_packages, collapse = "\n"), "\n")
    cat("\nInstall missing packages with:\n")
    cat(paste("install.packages(c(", paste(paste0('"', missing_packages, '"'), collapse = ", "), "))\n"))
    return(FALSE)
  } else {
    cat("✓ All required packages are available\n")
    return(TRUE)
  }
}

# Function to check configuration files
check_configuration <- function() {
  config_files <- c("config/test_config.R", "config/prod_config.R")
  missing_configs <- config_files[!file.exists(config_files)]
  
  if (length(missing_configs) > 0) {
    cat("⚠ WARNING: Missing configuration files:\n")
    cat(paste("  -", missing_configs, collapse = "\n"), "\n")
    cat("\nCopy templates and configure:\n")
    for (config in missing_configs) {
      template <- paste0(config, ".template")
      if (file.exists(template)) {
        cat(paste("cp", template, config, "\n"))
      }
    }
    return(FALSE)
  } else {
    cat("✓ Configuration files found\n")
    return(TRUE)
  }
}

# Function to create required directories
create_required_directories <- function() {
  required_dirs <- c("logs", "output", "plots")
  
  for (dir in required_dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
      cat(paste("Created directory:", dir, "\n"))
    }
  }
}

# Helper function to load toolkit modules
load_toolkit <- function() {
  cat("Loading GBIF Collections Registry Toolkit modules...\n")
  
  modules <- c(
    "src/connection/db_connection.R",
    "src/exploration/data_exploration.R",
    "src/quality_control/qc_checks.R",
    "src/analysis/data_analysis.R",
    "src/updates/db_updates.R"
  )
  
  for (module in modules) {
    if (file.exists(module)) {
      tryCatch({
        source(module)
        cat(paste("✓ Loaded:", basename(module), "\n"))
      }, error = function(e) {
        cat(paste("✗ Error loading", basename(module), ":", e$message, "\n"))
      })
    } else {
      cat(paste("✗ Module not found:", module, "\n"))
    }
  }
}

# Helper function for quick database connection
quick_connect <- function(env = "TEST") {
  if (exists("setup_database_connection")) {
    tryCatch({
      conn <- setup_database_connection(env)
      cat(paste("✓ Connected to", env, "environment\n"))
      return(conn)
    }, error = function(e) {
      cat(paste("✗ Connection failed:", e$message, "\n"))
      return(NULL)
    })
  } else {
    cat("✗ Connection module not loaded. Run load_toolkit() first.\n")
    return(NULL)
  }
}

# Helper function to show available scripts
show_scripts <- function() {
  cat("Available scripts:\n")
  scripts <- list.files("scripts", pattern = "\\.R$", full.names = FALSE)
  for (script in scripts) {
    cat(paste("  Rscript scripts/", script, " [arguments]\n", sep = ""))
  }
  cat("\nExample usage:\n")
  cat("  Rscript scripts/run_exploration.R TEST\n")
  cat("  Rscript scripts/run_qc_checks.R TEST\n")
  cat("  Rscript scripts/run_analysis.R TEST\n")
}

# Startup checks and setup
startup_checks <- function() {
  cat("\nRunning startup checks...\n")
  
  # Create required directories
  create_required_directories()
  
  # Check packages
  packages_ok <- check_required_packages()
  
  # Check configuration
  config_ok <- check_configuration()
  
  if (packages_ok && config_ok) {
    cat("✓ Environment setup complete\n")
    cat("\nQuick start:\n")
    cat("  load_toolkit()                     # Load all modules\n")
    cat("  conn <- quick_connect('TEST')      # Connect to TEST DB\n")
    cat("  show_scripts()                     # Show available scripts\n")
    cat("  ?setup_database_connection         # Get help on functions\n")
  } else {
    cat("⚠ Please resolve the issues above before proceeding\n")
  }
  
  cat("\nSecurity reminder: Never commit database credentials to Git!\n")
  cat("========================================\n")
}

# Safety check - warn if in production environment
if (Sys.getenv("R_ENV") == "production") {
  cat("🚨 WARNING: Running in PRODUCTION environment!\n")
  cat("🚨 Double-check all operations before execution!\n")
}

# Run startup checks
startup_checks()

# Clean up startup function from global environment
rm(startup_checks)

# Set up auto-completion (if available)
if (interactive() && requireNamespace("rstudioapi", quietly = TRUE)) {
  # RStudio-specific settings
  if (rstudioapi::isAvailable()) {
    cat("RStudio detected - enhanced features available\n")
  }
}

# Set default CRAN mirror
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://cloud.r-project.org/"
  options(repos = r)
})

# Suppress package startup messages for cleaner output
suppressPackageStartupMessages({
  # Pre-load essential packages silently
  library(utils)
  library(stats)
})

cat("Ready to use GBIF Collections Registry Toolkit!\n")
cat("Type show_scripts() to see available operations.\n\n")