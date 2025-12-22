#' Conectar con la base de datos METAGES
#'
#' Establece una conexión con la base de datos METAGES mediante un
#' túnel SSH y una conexión ODBC.
#'
#' La función depende de variables de entorno previamente configuradas
#' (por ejemplo, host, claves SSH y credenciales de base de datos).
#'
#' @details
#' La conexión se realiza en dos pasos:
#' \enumerate{
#'   \item Apertura de un túnel SSH.
#'   \item Conexión a la base de datos vía DBI/ODBC.
#' }
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

conectar_metages <- function() {


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
      Sys.getenv("test_ssh_bridge") # TEST env
      Sys.getenv("prod_ssh_bridge") # PROD env
      
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

                 Driver   = "MySQL ODBC 9.4 Unicode Driver",
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

