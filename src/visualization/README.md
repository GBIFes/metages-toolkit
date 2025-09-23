# Módulo de Visualización

Este módulo proporciona funciones para crear visualizaciones y análisis de dependencias del toolkit.

## Archivos:
- `function_dependencies.R`: Análisis y visualización de dependencias entre funciones

## Funciones:
- `analizar_dependencias_funciones()`: Analizar dependencias entre funciones del toolkit
- `crear_grafico_dependencias()`: Crear visualización interactiva de dependencias
- `generar_analisis_completo_dependencias()`: Análisis completo con múltiples formatos de salida

## Uso:
```r
# Cargar el módulo de visualización
source("src/visualization/function_dependencies.R")

# Analizar dependencias del toolkit
dependencias <- analizar_dependencias_funciones("src")

# Crear visualización interactiva
crear_grafico_dependencias(dependencias, "output/dependencias.html")

# Generar análisis completo
generar_analisis_completo_dependencias("src", "output/analysis")
```

## Tipos de Visualización:
- **HTML Interactivo**: Gráfico de red navegable con visNetwork
- **PNG Estático**: Imagen para documentación
- **PDF**: Gráfico vectorial para publicación

## Características:
- Codificación por colores según módulos
- Agrupación por funcionalidad
- Información detallada de dependencias
- Exportación en múltiples formatos