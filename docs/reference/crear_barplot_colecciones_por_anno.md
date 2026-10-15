# Evolucion anual del numero de colecciones registradas

Genera un grafico de barras que muestra, por año, el numero total
acumulado de colecciones registradas y el numero de colecciones creadas
en cada anno.

## Usage

``` r
crear_barplot_colecciones_por_anno(rdspath)
```

## Arguments

- rdspath:

  Ruta al directorio que contiene el archivo `colecciones_per_anno.rds`.

## Value

Un objeto `ggplot`.

## Details

Los datos se leen desde un archivo `.rds` incluido en el paquete
metagesToolkit, accedido a traves de la ruta indicada en el argumento
`rdspath`.

## See also

[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)

## Examples

``` r
if (FALSE) { # \dontrun{
crear_barplot_colecciones_por_anno(
  rdspath = "reports/data/vistas_sql"
)
} # }
```
