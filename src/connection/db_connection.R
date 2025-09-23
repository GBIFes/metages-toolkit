# Módulo de Conexión a Base de Datos para Registro de Colecciones GBIF España
# Este módulo proporciona funciones para conectar a bases de datos MySQL via túnel SSH para entornos PROD y TEST
# IMPORTANTE: El túnel SSH debe estar abierto previamente usando bash

# Cargar librerías requeridas
library(DBI)
library(odbc)
library(pool)
library(logging)

#' Configurar Conexión a Base de Datos
#' 
#' Establece una conexión a la base de datos MySQL via túnel SSH basado en el entorno especificado
#' NOTA: Este función asume que el túnel SSH ya está establecido via bash
#' 
#' @param environment Character. "PROD" o "TEST"
#' @param use_pool Logical. Si usar pooling de conexiones (default: TRUE)
#' @return Objeto de conexión a base de datos o pool
#' @export
setup_database_connection <- function(environment = "PROD", use_pool = TRUE) {
  
  # Validar parámetro de entorno
  if (!environment %in% c("PROD", "TEST")) {
    stop("El entorno debe ser 'PROD' o 'TEST'")
  }
  
  # Cargar configuración apropiada
  config_file <- paste0("config/", tolower(environment), "_config.R")
  
  if (!file.exists(config_file)) {
    stop(paste("Archivo de configuración no encontrado:", config_file, 
               "\nPor favor copia la plantilla y configura tus credenciales."))
  }
  
  source(config_file)
  
  # Obtener configuración basada en el entorno
  db_config <- if (environment == "PROD") DB_CONFIG_PROD else DB_CONFIG_TEST
  
  # Configurar logging
  setup_logging(db_config)
  
  loginfo(paste("Intentando conectar a la base de datos", environment, "via túnel SSH externo"))
  
  # IMPORTANTE: Verificar que el túnel SSH esté activo
  if (!check_ssh_tunnel_active(db_config$local_port)) {
    stop(paste("Túnel SSH no está activo en puerto", db_config$local_port, 
               "\nPor favor ejecuta el comando bash para abrir el túnel:",
               "\nssh -i", db_config$ssh_keyfile, "-p", db_config$ssh_port,
               paste0(db_config$ssh_user, "@", db_config$ssh_host),
               "-L", paste0(db_config$local_port, ":localhost:", db_config$remote_port)))
  }
  
  tryCatch({
    if (use_pool) {
      # Crear pool de conexiones para mejor rendimiento
      connection <- dbPool(
        drv = odbc::odbc(),
        driver = db_config$odbc_driver,
        server = "127.0.0.1",  # Punto final local del túnel SSH
        port = db_config$local_port,
        dbname = db_config$database,
        uid = db_config$username,
        pwd = db_config$password,
        charset = db_config$charset,
        minSize = 1,
        maxSize = db_config$pool_size
      )
    } else {
      # Crear conexión individual
      connection <- dbConnect(
        odbc::odbc(),
        driver = db_config$odbc_driver,
        server = "127.0.0.1",  # Punto final local del túnel SSH
        port = db_config$local_port,
        database = db_config$database,
        uid = db_config$username,
        pwd = db_config$password,
        charset = db_config$charset
      )
    }
    
    loginfo(paste("Conectado exitosamente a la base de datos", environment, "via túnel SSH externo"))
    
    # Probar la conexión
    if (test_connection(connection)) {
      return(connection)
    } else {
      stop("La prueba de conexión falló")
    }
    
  }, error = function(e) {
    logerror(paste("Falló la conexión a la base de datos", environment, ":", e$message))
    stop(e)
  })
}

#' Verificar si el Túnel SSH está Activo
#' 
#' Verifica si hay un túnel SSH activo en el puerto especificado
#' 
#' @param port Numeric. Puerto local del túnel SSH
#' @return Logical indicando si el túnel está activo
check_ssh_tunnel_active <- function(port) {
  tryCatch({
    # Intentar crear una conexión de prueba al puerto local
    test_conn <- socketConnection(host = "127.0.0.1", port = port, 
                                  open = "r+", blocking = FALSE, timeout = 2)
    close(test_conn)
    return(TRUE)
  }, error = function(e) {
    return(FALSE)
  })
}



#' Probar Conexión a Base de Datos
#' 
#' Prueba si la conexión a la base de datos está funcionando correctamente
#' 
#' @param connection Objeto de conexión a base de datos
#' @return Logical indicando si la conexión funciona
#' @export
test_connection <- function(connection) {
  tryCatch({
    # Consulta simple para probar la conexión
    result <- dbGetQuery(connection, "SELECT 1 as test")
    
    if (nrow(result) == 1 && result$test == 1) {
      loginfo("Prueba de conexión a base de datos exitosa")
      return(TRUE)
    } else {
      logwarn("La prueba de conexión devolvió un resultado inesperado")
      return(FALSE)
    }
    
  }, error = function(e) {
    logerror(paste("Falló la prueba de conexión a base de datos:", e$message))
    return(FALSE)
  })
}

#' Cerrar Conexión a Base de Datos
#' 
#' Cierra de forma segura la conexión/pool a la base de datos
#' 
#' @param connection Objeto de conexión a base de datos o pool
#' @export
close_database_connection <- function(connection) {
  tryCatch({
    if (inherits(connection, "Pool")) {
      poolClose(connection)
      loginfo("Pool de conexión a base de datos cerrado")
    } else {
      dbDisconnect(connection)
      loginfo("Conexión a base de datos cerrada")
    }
  }, error = function(e) {
    logwarn(paste("Error cerrando conexión a base de datos:", e$message))
  })
}

#' Obtener Información de Conexión
#' 
#' Devuelve información sobre la conexión actual a la base de datos
#' 
#' @param connection Objeto de conexión a base de datos
#' @return Lista con detalles de conexión
#' @export
get_connection_info <- function(connection) {
  tryCatch({
    info <- dbGetInfo(connection)
    
    # Obtener versión de base de datos y otra información
    version_query <- dbGetQuery(connection, "SELECT VERSION() as version")
    current_db <- dbGetQuery(connection, "SELECT DATABASE() as current_database")
    
    result <- list(
      driver = "ODBC",
      server_version = version_query$version,
      current_database = current_db$current_database,
      connection_valid = dbIsValid(connection),
      ssh_tunnel = "Externo (bash)",
      connection_type = "Túnel SSH + ODBC"
    )
    
    return(result)
    
  }, error = function(e) {
    logwarn(paste("No se pudo obtener información de conexión:", e$message))
    return(NULL)
  })
}

#' Configurar Logging
#' 
#' Configura el logging para operaciones de base de datos
#' 
#' @param config Lista de configuración de base de datos
setup_logging <- function(config) {
  # Crear directorio de logs si no existe
  log_dir <- dirname(config$LOG_FILE)
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE)
  }
  
  # Configurar logging
  basicConfig(level = config$LOG_LEVEL)
  addHandler(writeToFile, file = config$LOG_FILE)
}

#' Ejecutar Consulta Segura
#' 
#' Ejecuta una consulta con manejo de errores y logging apropiado
#' 
#' @param connection Conexión a base de datos
#' @param query Cadena de consulta SQL
#' @param params Lista de parámetros para consultas parametrizadas
#' @return Resultado de consulta o NULL si hay error
#' @export
execute_safe_query <- function(connection, query, params = NULL) {
  tryCatch({
    logdebug(paste("Ejecutando consulta:", query))
    
    if (is.null(params)) {
      result <- dbGetQuery(connection, query)
    } else {
      result <- dbGetQuery(connection, query, params = params)
    }
    
    logdebug(paste("Consulta ejecutada exitosamente, devolvió", nrow(result), "filas"))
    return(result)
    
  }, error = function(e) {
    logerror(paste("Falló la ejecución de consulta:", e$message))
    logerror(paste("Consulta:", query))
    return(NULL)
  })
}