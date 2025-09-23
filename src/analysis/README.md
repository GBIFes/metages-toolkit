# Módulo de Análisis de Datos

Este módulo proporciona funciones para analizar datos en la base de datos del Registro de Colecciones GBIF España.

## Archivos:
- `data_analysis.R`: Funciones de análisis para datos de colecciones e instituciones

## Funciones:
- `analizar_tendencias_colecciones()`: Analizar tendencias en datos de colecciones a lo largo del tiempo
- `analizar_cobertura_institucional()`: Analizar cobertura geográfica y taxonómica
- `analizar_patrones_datos()`: Identificar patrones y anomalías en los datos
- `analizar_tendencias_completitud()`: Seguir completitud de datos a lo largo del tiempo
- `generar_dashboard_analiticas()`: Crear analíticas de resumen
- `exportar_resultados_analisis()`: Exportar resultados de análisis a varios formatos

## Uso:
```r
# Cargar el módulo de análisis
source("src/analysis/data_analysis.R")

# Cargar módulo de conexión
source("src/connection/db_connection.R")

# Conectar a base de datos
conn <- setup_database_connection("PROD")

# Ejecutar análisis específicos
tendencias <- analizar_tendencias_colecciones(conn)
cobertura <- analizar_cobertura_institucional(conn)

# Generar analíticas comprehensivas
dashboard <- generar_dashboard_analiticas(conn)

# Exportar resultados
exportar_resultados_analisis(dashboard, "reporte_analiticas")
```