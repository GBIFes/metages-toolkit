# Módulo de Conexión a Base de Datos

Este módulo maneja conexiones de base de datos para entornos PROD y TEST.

## Archivos:
- `db_connection.R`: Funciones principales de conexión a base de datos

## Funciones:
- `setup_database_connection()`: Establece conexión basada en entorno
- `close_database_connection()`: Cierra conexiones de base de datos de forma segura
- `test_connection()`: Prueba conectividad de base de datos
- `get_connection_info()`: Devuelve información de estado de conexión

## Uso:
```r
# Cargar el módulo de conexión
source("src/connection/db_connection.R")

# Conectar a base de datos de producción
prod_conn <- setup_database_connection("PROD")

# Conectar a base de datos de pruebas
test_conn <- setup_database_connection("TEST")

# Probar conexión
test_connection(prod_conn)

# Cerrar conexión cuando termine
close_database_connection(prod_conn)
```