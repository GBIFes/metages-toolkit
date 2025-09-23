# Módulo de Control de Calidad

Este módulo proporciona funciones para implementar verificaciones de control de calidad en la base de datos del Registro de Colecciones GBIF España.

## Archivos:
- `qc_checks.R`: Funciones de verificación de control de calidad

## Funciones:
- `ejecutar_verificaciones_completitud()`: Verificar completitud de datos entre tablas
- `ejecutar_verificaciones_consistencia()`: Verificar consistencia de datos e integridad referencial
- `ejecutar_verificaciones_validez()`: Validar formatos de datos y restricciones
- `ejecutar_verificaciones_reglas_negocio()`: Aplicar reglas de negocio específicas de GBIF España
- `ejecutar_todas_verificaciones_cc()`: Ejecutar todas las verificaciones de control de calidad
- `generar_reporte_cc()`: Generar reporte comprehensivo de CC

## Uso:
```r
# Cargar el módulo de CC
source("src/quality_control/qc_checks.R")

# Cargar módulo de conexión
source("src/connection/db_connection.R")

# Conectar a base de datos
conn <- setup_database_connection("TEST")

# Ejecutar verificaciones específicas
resultados_completitud <- ejecutar_verificaciones_completitud(conn)
resultados_consistencia <- ejecutar_verificaciones_consistencia(conn)

# Ejecutar todas las verificaciones
todos_resultados <- ejecutar_todas_verificaciones_cc(conn)

# Generar reporte de CC
reporte_cc <- generar_reporte_cc(conn, "reporte_cc.html")
```