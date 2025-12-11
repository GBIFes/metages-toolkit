#######################################################################
# Title: Script para migrar scripts de DBeaver a github (version control)
#
# Created by: Ruben Perez Perez (GBIF.ES) 
# Creation Date: Thu Dec 11 16:26:05 2025
#######################################################################

sync_dbeaver_scripts <- function(src, dst = "./inst/sql/scripts") {
  
  # Archivos en origen y destino
  src_files <- list.files(src, full.names = TRUE)
  dst_files <- list.files(dst, full.names = TRUE)
  
  # Copiar o reemplazar archivos del origen al destino
  file.copy(src_files, dst, overwrite = TRUE)
  
  # Borra archivos que están en destino pero NO en origen
  file.remove(setdiff(dst_files, file.path(dst, basename(src_files))))
}


# Usando la funcion
sync_dbeaver_scripts(src = Sys.getenv("SQL_scripts"))
