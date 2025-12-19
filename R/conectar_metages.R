#######################################################################
# Title: Script to connect to metages DB
#
# Created by: Ruben Perez Perez (GBIF.ES) 
# Creation Date: Fri Sep 19 16:42:44 2025
#######################################################################

# Instalar paquetes
pkgs <- c("DBI", "odbc", "ssh", "processx")

# instala los que falten y cárgalos
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}


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

