# Módulo de Generación de Reportes

Este módulo proporciona funciones para generar reportes estilo GBIF España sobre el estado del Registro de Colecciones.

## Archivos:
- `report_generation.R`: Funciones para generar reportes comprehensivos

## Funciones:
- `generar_reporte_colecciones()`: Generar reporte principal estilo GBIF España
- `recopilar_estadisticas_registro()`: Recopilar estadísticas del registro
- `generar_graficos_distribucion()`: Crear gráficos de distribución geográfica y taxonómica
- `exportar_reporte()`: Exportar reporte en múltiples formatos

## Uso:
```r
# Cargar el módulo de reportes
source("src/reports/report_generation.R")

# Cargar módulo de conexión
source("src/connection/db_connection.R")

# Conectar a base de datos
conn <- setup_database_connection("PROD")

# Generar reporte completo
reporte <- generar_reporte_colecciones(conn, "output", "2024", "html")

# Generar solo estadísticas
estadisticas <- recopilar_estadisticas_registro(conn)
```

## Formatos de Salida:
- HTML: Reporte interactivo para visualización web
- PDF: Documento imprimible de alta calidad
- Word: Documento editable para revisión

## Plantillas:
Los reportes se basan en el formato establecido por GBIF España, similar a:
https://www.gbif.es/wp-content/uploads/2021/10/Informe_colecciones2021.pdf