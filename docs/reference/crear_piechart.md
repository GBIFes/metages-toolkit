# Crear grafico de sectores (pie chart) a partir de tablas agregadas

Genera un grafico de sectores que representa la proporcion relativa de
recursos o colecciones por categoria a partir de una tabla agregada.

## Usage

``` r
crear_piechart(rds_path, categoria, valor)
```

## Arguments

- rds_path:

  Ruta a un archivo `.rds` que contiene un `data.frame` con los datos
  agregados.

- categoria:

  Nombre de la columna categórica (caracter) que define los sectores del
  grafico (disciplinas o sectores).

- valor:

  Nombre de la columna numérica que contiene el peso de cada categoría
  (por ejemplo, numero de recursos o colecciones).

## Value

Un objeto `ggplot` que representa un grafico de sectores.

## Details

La funcion espera datos ya agregados por categoria. Si existen varias
filas con la misma categoria, sus valores se suman internamente antes de
calcular las proporciones.

## Examples

``` r
if (FALSE) { # \dontrun{
crear_piechart(
 rds_path = ruta_a_archivo_rds,
 categoria = "sector",
 valor = "n_recursos")
} # }
```
