# Ejemplo de Archivo de Configuración Externa
# Este archivo debe estar fuera del repositorio Git y contener las credenciales reales
# Ubicación recomendada: ~/Documents/R/config_gbif.es_dbconnect

# Configuración para entorno de PRODUCCIÓN
# Host y puerto pueden variar por usuario - actualizar según tu configuración
PROD_HOST <- "tu-host-prod.gbif.es"   # Ejemplo: "dbserver1.gbif.es"
PROD_PORT <- 3306                      # Puerto estándar MySQL, puede variar
PROD_DATABASE <- "gbif_wp"            # Base de datos del registro de colecciones
PROD_UID <- "tu_usuario_prod"         # Tu usuario de base de datos PROD
PROD_PASSWORD <- "tu_password_prod"   # Tu contraseña de base de datos PROD

# Configuración para entorno de PRUEBAS
# Host y puerto pueden variar por usuario - actualizar según tu configuración  
TEST_HOST <- "tu-host-test.gbif.es"   # Ejemplo: "testdb.gbif.es"
TEST_PORT <- 3306                      # Puerto estándar MySQL, puede variar
TEST_DATABASE <- "gbif_wp_test"       # Base de datos de pruebas
TEST_UID <- "tu_usuario_test"         # Tu usuario de base de datos TEST
TEST_PASSWORD <- "tu_password_test"   # Tu contraseña de base de datos TEST

# Configuración SSH para túnel (común para ambos entornos)
SSH_HOST <- "mola.gbif.es"            # Servidor SSH de GBIF.ES
SSH_PORT <- 22002                     # Puerto SSH específico
SSH_USER <- "tu_usuario_ssh"          # Tu usuario SSH (ej: "rubenp")
SSH_KEYFILE <- "~/.ssh/id_rsa"        # Ruta a tu clave privada SSH

# Configuración local de túnel SSH
# IMPORTANTE: Estos puertos deben estar libres en tu máquina local
LOCAL_PORT_PROD <- 3307               # Puerto local para túnel PROD
LOCAL_PORT_TEST <- 3308               # Puerto local para túnel TEST (diferente para evitar conflictos)

# Driver ODBC - verificar con odbc::odbcListDrivers()
ODBC_DRIVER <- "MySQL ODBC 9.4 ANSI Driver"  # Ajustar según tu sistema

# INSTRUCCIONES PARA ABRIR TÚNELES SSH:
# 
# Para PRODUCCIÓN:
# Ejecutar en bash/terminal ANTES de usar R:
# ssh -i ~/.ssh/id_rsa -p 22002 tu_usuario_ssh@mola.gbif.es -L 3307:tu-host-prod.gbif.es:3306
#
# Para PRUEBAS:  
# Ejecutar en bash/terminal ANTES de usar R:
# ssh -i ~/.ssh/id_rsa -p 22002 tu_usuario_ssh@mola.gbif.es -L 3308:tu-host-test.gbif.es:3306
#
# MANTENER estas conexiones SSH abiertas mientras trabajas con R

# Variables de compatibilidad (nombres alternativos usados en scripts existentes)
UID <- TEST_UID                       # Para compatibilidad con scripts existentes
gbif_wp_pass <- TEST_PASSWORD         # Para compatibilidad con scripts existentes
Database <- TEST_DATABASE             # Para compatibilidad con scripts existentes