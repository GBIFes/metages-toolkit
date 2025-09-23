# .Rprofile para el Toolkit del Registro de Colecciones GBIF España
# Este archivo se carga automáticamente cuando R se inicia en este directorio de proyecto

# Mostrar mensaje de bienvenida
cat("========================================\n")
cat("GBIF Spain Collections Registry Toolkit\n")
cat("GBIF.ES - Registro de Colecciones\n")
cat("https://gbif.es/registro-colecciones/\n")
cat("========================================\n")

# Configurar opciones de R para mejor experiencia de desarrollo
options(
  # Opciones generales
  width = 120,
  max.print = 1000,
  scipen = 999,  # Evitar notación científica
  digits = 4,
  
  # Opciones de desarrollo
  error = traceback,
  warn = 1,  # Mostrar advertencias según ocurren
  
  # Opciones de base de datos
  timeout = 60,  # Tiempo límite por defecto para operaciones
  encoding = "UTF-8",
  
  # Opciones de salida
  stringsAsFactors = FALSE  # Por defecto para versiones antiguas de R
)

# Establecer zona horaria (ajustar según necesidades organizacionales)
Sys.setenv(TZ = "Europe/Madrid")

# Verificar y activar renv si está disponible
if (file.exists("renv.lock") && requireNamespace("renv", quietly = TRUE)) {
  cat("Activando entorno renv...\n")
  renv::activate()
}

# Función para verificar paquetes requeridos
check_required_packages <- function() {
  required_packages <- c(
    "DBI",
    "odbc",     # Para conexiones ODBC a MySQL
    "pool",     # Para pooling de conexiones
    "dplyr",    # Manipulación de datos
    "ggplot2",  # Visualizaciones
    "plotly",   # Gráficos interactivos
    "lubridate", # Manejo de fechas
    "tidyr",    # Reestructuración de datos
    "scales",   # Escalas para gráficos
    "stringr",  # Manipulación de cadenas
    "logging",  # Sistema de logging
    "uuid",     # Generación de IDs únicos
    "jsonlite", # Manejo de JSON
    "knitr",    # Generación de reportes
    "rmarkdown", # Documentos R Markdown
    "igraph",   # Análisis de grafos (dependencias)
    "visNetwork" # Visualización interactiva de redes
  )
  
  missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
  
  if (length(missing_packages) > 0) {
    cat("⚠ ADVERTENCIA: Faltan paquetes requeridos:\n")
    cat(paste("  -", missing_packages, collapse = "\n"), "\n")
    cat("\nInstalar paquetes faltantes con:\n")
    cat(paste("install.packages(c(", paste(paste0('"', missing_packages, '"'), collapse = ", "), "))\n"))
    return(FALSE)
  } else {
    cat("✓ Todos los paquetes requeridos están disponibles\n")
    return(TRUE)
  }
}

# Función para verificar archivos de configuración
check_configuration <- function() {
  config_files <- c("config/test_config.R", "config/prod_config.R")
  missing_configs <- config_files[!file.exists(config_files)]
  
  if (length(missing_configs) > 0) {
    cat("⚠ ADVERTENCIA: Faltan archivos de configuración:\n")
    cat(paste("  -", missing_configs, collapse = "\n"), "\n")
    cat("\nCopiar plantillas y configurar:\n")
    for (config in missing_configs) {
      template <- paste0(config, ".template")
      if (file.exists(template)) {
        cat(paste("cp", template, config, "\n"))
      }
    }
    return(FALSE)
  } else {
    cat("✓ Archivos de configuración encontrados\n")
    return(TRUE)
  }
}

# Función para crear directorios requeridos
create_required_directories <- function() {
  required_dirs <- c("logs", "output", "plots")
  
  for (dir in required_dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
      cat(paste("Directorio creado:", dir, "\n"))
    }
  }
}

# Función auxiliar para cargar módulos del toolkit
load_toolkit <- function() {
  cat("Cargando módulos del Toolkit del Registro de Colecciones GBIF España...\n")
  
  modules <- c(
    "src/connection/db_connection.R",
    "src/exploration/data_exploration.R",
    "src/quality_control/qc_checks.R",
    "src/analysis/data_analysis.R"
  )
  
  for (module in modules) {
    if (file.exists(module)) {
      tryCatch({
        source(module)
        cat(paste("✓ Cargado:", basename(module), "\n"))
      }, error = function(e) {
        cat(paste("✗ Error cargando", basename(module), ":", e$message, "\n"))
      })
    } else {
      cat(paste("✗ Módulo no encontrado:", module, "\n"))
    }
  }
}

# Función auxiliar para conexión rápida a base de datos
quick_connect <- function(env = "TEST") {
  if (exists("setup_database_connection")) {
    tryCatch({
      conn <- setup_database_connection(env)
      cat(paste("✓ Conectado al entorno", env, "\n"))
      return(conn)
    }, error = function(e) {
      cat(paste("✗ Falló la conexión:", e$message, "\n"))
      return(NULL)
    })
  } else {
    cat("✗ Módulo de conexión no cargado. Ejecuta load_toolkit() primero.\n")
    return(NULL)
  }
}

# Función auxiliar para mostrar scripts disponibles
show_scripts <- function() {
  cat("Scripts disponibles:\n")
  scripts <- list.files("scripts", pattern = "\\.R$", full.names = FALSE)
  # Filtrar scripts de actualización
  scripts <- scripts[!grepl("update", scripts)]
  for (script in scripts) {
    cat(paste("  Rscript scripts/", script, " [argumentos]\n", sep = ""))
  }
  cat("\nEjemplos de uso:\n")
  cat("  Rscript scripts/run_exploration.R TEST\n")
  cat("  Rscript scripts/run_qc_checks.R TEST\n")
  cat("  Rscript scripts/run_analysis.R TEST\n")
}

# Verificaciones de inicio y configuración
startup_checks <- function() {
  cat("\nEjecutando verificaciones de inicio...\n")
  
  # Crear directorios requeridos
  create_required_directories()
  
  # Verificar paquetes
  packages_ok <- check_required_packages()
  
  # Verificar configuración
  config_ok <- check_configuration()
  
  if (packages_ok && config_ok) {
    cat("✓ Configuración del entorno completa\n")
    cat("\nInicio rápido:\n")
    cat("  load_toolkit()                     # Cargar todos los módulos\n")
    cat("  conn <- quick_connect('TEST')      # Conectar a BD TEST\n")
    cat("  show_scripts()                     # Mostrar scripts disponibles\n")
    cat("  ?setup_database_connection         # Obtener ayuda sobre funciones\n")
  } else {
    cat("⚠ Por favor resuelve los problemas anteriores antes de continuar\n")
  }
  
  cat("\nRecordatorio de seguridad: ¡Nunca confirmes credenciales de BD en Git!\n")
  cat("========================================\n")
}

# Verificación de seguridad - advertir si está en entorno de producción
if (Sys.getenv("R_ENV") == "production") {
  cat("🚨 ADVERTENCIA: ¡Ejecutándose en entorno de PRODUCCIÓN!\n")
  cat("🚨 ¡Verifica todas las operaciones antes de ejecutar!\n")
}

# Ejecutar verificaciones de inicio
startup_checks()

# Limpiar función de inicio del entorno global
rm(startup_checks)

# Configurar autocompletado (si está disponible)
if (interactive() && requireNamespace("rstudioapi", quietly = TRUE)) {
  # Configuraciones específicas de RStudio
  if (rstudioapi::isAvailable()) {
    cat("RStudio detectado - funciones mejoradas disponibles\n")
  }
}

# Establecer espejo CRAN por defecto
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://cloud.r-project.org/"
  options(repos = r)
})

# Suprimir mensajes de inicio de paquetes para salida más limpia
suppressPackageStartupMessages({
  # Pre-cargar paquetes esenciales silenciosamente
  library(utils)
  library(stats)
})

cat("¡Listo para usar el Toolkit del Registro de Colecciones GBIF España!\n")
cat("Escribe show_scripts() para ver las operaciones disponibles.\n")
cat("Visita: https://gbif.es/registro-colecciones/\n")
cat("IMPORTANTE: Asegúrate de abrir el túnel SSH antes de conectar a la BD.\n\n")