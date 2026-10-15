# Crear grafico de top colecciones por número de registros

Genera un grafico de barras horizontales con las 10 colecciones con
mayor numero de registros que publican en GBIF, a partir de un objeto
leido desde un archivo `.rds` interno de metagesToolkit.

## Usage

``` r
crear_barplot_top_colecciones_pub(rds_path)
```

## Arguments

- rds_path:

  Ruta al archivo `.rds` que contiene el mapa de colecciones.

## Value

Un objeto `ggplot`.
