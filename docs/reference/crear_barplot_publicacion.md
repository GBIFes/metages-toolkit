# Grafico de barras apiladas sobre el estado de publicacion en GBIF

Genera un grafico de barras horizontales apiladas que muestra, por
disciplina, el numero de entidades o colecciones que publican y no
publican datos en GBIF.

## Usage

``` r
crear_barplot_publicacion(rdspath, nivel = c("entidades", "colecciones"))
```

## Arguments

- rdspath:

  Ruta al directorio que contiene los archivos
  `entidades_per_publican.rds` y `colecciones_per_publican.rds`.

- nivel:

  Caracter. Indica el nivel de agregacion del grafico. Debe ser uno de:

  - `"entidades"`: numero de entidades

  - `"colecciones"`: numero de colecciones y bases de datos

## Value

Un objeto `ggplot` con el grafico de barras apiladas.

## Details

Los datos se leen desde archivos `.rds` incluidos en el paquete
metagesToolkit, accedidos a traves de la ruta indicada en el argumento
`rdspath`.

El grafico se ordena de menor a mayor segun el total de entidades o
colecciones por disciplina. Se excluye la fila `"TOTAL GENERAL"` si esta
presente en los datos. Los archivos `.rds` deben contener las columnas
`disciplina_def`, `estado_publicacion` y `total_colecciones` o
`total_entidades`.

## See also

[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html),
[`fct_reorder`](https://forcats.tidyverse.org/reference/fct_reorder.html)

## Examples

``` r
if (FALSE) { # \dontrun{
crear_barplot_publicacion(rdspath = "reports/data/vistas_sql",
                          nivel = "entidades")
} # }
```
