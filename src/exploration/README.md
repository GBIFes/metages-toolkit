# Módulo de Exploración de Datos

Este módulo proporciona funciones para explorar la base de datos del Registro de Colecciones GBIF España.

## Archivos:
- `data_exploration.R`: Funciones para exploración de base de datos y perfilado de datos

## Funciones:
- `explorar_esquema_base_datos()`: Obtener visión general de estructura de base de datos
- `explorar_estructura_tabla()`: Analizar estructura de tabla específica
- `obtener_resumen_datos()`: Generar resúmenes de datos y estadísticas
- `explorar_calidad_datos()`: Evaluación básica de calidad de datos
- `generar_reporte_exploracion()`: Crear reporte comprehensivo de exploración

## Uso:
```r
# Cargar el módulo de exploración
source("src/exploration/data_exploration.R")

# Cargar módulo de conexión
source("src/connection/db_connection.R")

# Conectar a base de datos
conn <- setup_database_connection("TEST")

# Explorar esquema de base de datos
info_esquema <- explorar_esquema_base_datos(conn)

# Explorar tabla específica
info_tabla <- explorar_estructura_tabla(conn, "colecciones")

# Generar estadísticas de resumen
estadisticas_resumen <- obtener_resumen_datos(conn, "colecciones")

# Generar reporte completo de exploración
reporte <- generar_reporte_exploracion(conn)
```