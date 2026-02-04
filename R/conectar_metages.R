#' Conectar con la base de datos METAGES
#'
#' Establece una conexión con la base de datos METAGES mediante un
#' túnel SSH y una conexión ODBC.
#'
#' La función depende de variables de entorno previamente configuradas
#' (por ejemplo, host, claves SSH y credenciales de base de datos).
#' Para mas informacion sobre la configuracion de las variables de entorno, ver 
#' \href{https://gbifes.github.io/metages-toolkit/articles/guia-uso-dev.html#configuracion-de--renviron-para-acceder-a-metages}{Documentación técnica de metagesToolkit}
#'
#'
#' @param driver Nombre del driver ODBC a utilizar. Por defecto se usa
#'   `"MySQL ODBC 9.4 Unicode Driver"`, pero puede variar segun el sistema
#'   operativo y la instalacion local. 
#'   **Solo se admiten drivers ODBC Unicode**. Los drivers ANSI no estan soportados. 
#'   Para listar los drivers disponibles desde R: \code{odbc::odbcListDrivers()}.
#'   En sistemas donde el driver por defecto no funcione, el usuario 
#'   deberá especificar uno alternativo mediante el argumento \code{driver}.
#'
#'
#' @details
#' La conexión se realiza en dos pasos:
#' \enumerate{
#'   \item Apertura de un túnel SSH.
#'   \item Conexión a la base de datos vía \pkg{DBI} y \pkg{ODBC}.
#' }
#' La base de datos MetaGES utiliza codificacion UTF-8 y contiene caracteres
#' internacionales (acentos, caracteres cientificos, etc.).
#'
#' Por este motivo, \code{conectar_metages()} **solo permite el uso de drivers ODBC Unicode**. 
#' Los drivers ODBC ANSI no soportan correctamente UTF-8 y pueden
#' provocar errores silenciosos o corrupcion de texto.
#'
#' Si no se especifica un driver, la función utiliza el driver Unicode por
#' defecto. Si dicho driver no está instalado en el sistema, la conexión
#' fallará.
#'
#' Para instalar un driver ODBC Unicode para MySQL, consulte la página oficial:
#' \url{https://dev.mysql.com/downloads/connector/odbc/}
#'
#'
#' @return Una lista con dos elementos:
#' \describe{
#'   \item{con}{Conexión DBI a la base de datos.}
#'   \item{tunnel}{Objeto del túnel SSH.}
#' }
#'
#' @import DBI
#' @import odbc
#' @import ssh
#' @import processx
#'
#' @export

conectar_metages <- function(driver = NULL) {

  
  # ---------------------------------------------------------------
  # Comprobar que las variables de ambiente necesarias existen.
  # ---------------------------------------------------------------
  required_env <- c(
    "host_prod",
    "keyfile",
    "prod_ssh_bridge_R",
    "Database",
    "UID",
    "gbif_wp_pass"
  )
  
  missing <- required_env[Sys.getenv(required_env) == ""]
  
  if (length(missing) > 0) {
    stop(
      "Missing required environment variables: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  
  
  # ---------------------------------------------------------------
  # Usar driver ODBC por defecto si no se especifica.
  # ---------------------------------------------------------------
  default_driver <- "MySQL ODBC 9.4 Unicode Driver"
  
  if (is.null(driver) || identical(driver, "")) {
    driver <- default_driver
  }
  
  # Comprobacion de seguridad
  if (!is.character(driver) || length(driver) != 1) {
    stop(
      "`driver` debe ser una cadena de texto de longitud 1.",
      call. = FALSE
    )
  }
  
  
  
  # ---------------------------------------------------------------
  # Comprobar que el driver ODBC existe
  # ---------------------------------------------------------------
  available_drivers <- odbc::odbcListDrivers()$name
  
  if (!driver %in% available_drivers) {
    stop(
      "ODBC driver not found: '", driver, "'.\n",
      "Available drivers:\n",
      paste(available_drivers, collapse = ", "),
      call. = FALSE
    )
  }
  
  # ---------------------------------------------------------------
  # Conexión SSH
  # --------------------------------------------------------------- 

# Credenciales SSH. Ajusta la ruta a tu clave privada
session <- ssh::ssh_connect(
  # host = Sys.getenv("host_test"), #TEST
  host = Sys.getenv("host_prod"),   #PROD
  keyfile = Sys.getenv("keyfile")
)


# Abrir túnel SSH local para conectarse a la base de datos
    # Solo funciona desde fuera de Joaquin Costa 22
    # (Mobile Hotspot si estas en la ofi o AnyDesk)

  # DESDE CMD:
      # Pegar el resultado en CMD y clicar "Enter"
      # Sys.getenv("test_ssh_bridge") # TEST env
      # Sys.getenv("prod_ssh_bridge") # PROD env
      
      # Dejar tunel abierto mientras trabajas!
      
      # Cerrar tunel SSH
      # En CMD correr: 
      # exit
  
  
  # DESDE R:
      # Desagregar codigo del tunel para su procesado por processx 
      args <- strsplit(Sys.getenv("prod_ssh_bridge_R"), " ")[[1]]
  
      # Apertura del tunel en segundo plano para poder seguir trabajando en R
      tunnel <- process$new(
        "ssh",
        args,
        supervise = TRUE
      )
  
      # Comprobar que el tunel esta abierto      
      tunnel$is_alive()
      
      # Cerrar tunel cuado hayamos acabado
      # tunnel$kill()



# Conectar a la base de datos
con <- dbConnect(odbc(),
  # Si el Driver seleccionado no funciona, poner uno que funcione en tu equipo.
  # Para ver cuales funcionan, corre: 
  # Subset: subset(odbc::odbcListDrivers(), attribute == "UsageCount") 
  # Lista completa: odbc::odbcListDrivers()

                 Driver   = driver,
                 Server   = "127.0.0.1",
                 Port     = 3307,          # el puerto del túnel local
                 Database = Sys.getenv("Database"),
                 UID      = Sys.getenv("UID"),
                 PWD      = Sys.getenv("gbif_wp_pass"),
                 encoding = "UTF-8")



# Desconectar de la Base de Datos cuando hayamos acabado
# dbDisconnect(con)

# Devolver conexion y tunel (si existe)
list(
  con = con,
  tunnel = tunnel
)

}

