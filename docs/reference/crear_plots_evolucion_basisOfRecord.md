# Evolucion anual de registros GBIF por naturaleza (Observaciones vs Especimenes)

Genera dos graficos comparativos de la evolucion anual del numero de
registros publicados en GBIF.ES, diferenciando entre:

## Usage

``` r
crear_plots_evolucion_basisOfRecord(
  year_ini = 1840,
  year_fin = as.integer(format(Sys.Date(), "%Y"))
)
```

## Arguments

- year_ini:

  Anno inicial (inclusive) a partir del cual se recuperan los registros.
  Por defecto, 1840.

- year_fin:

  Anno final (inclusive). Por defecto, el anno actual.

## Value

Una lista con tres elementos:

- lineal:

  Objeto `ggplot` con grafico en escala lineal y doble eje Y.

- log:

  Objeto `ggplot` con grafico en escala logaritmica (log10).

- data:

  `data.frame` en formato ancho con columnas: `year`, `Observaciones`,
  `Especimenes`.

## Details

- **Observaciones** (HUMAN_OBSERVATION, MACHINE_OBSERVATION,
  OBSERVATION)

- **Especimenes** (PRESERVED_SPECIMEN, MATERIAL_SAMPLE, FOSSIL_SPECIMEN)

La funcion descarga los datos una unica vez mediante galah y construye:

1.  Un grafico en escala lineal con doble eje Y (ajustado mediante
    factor de escala).

2.  Un grafico en escala logaritmica (log10) con eje unico.

Ademas, devuelve el conjunto de datos agregado en formato ancho para su
reutilizacion.

Los datos se obtienen dinamicamente desde el nodo **GBIF.ES** utilizando
galah. El grafico en escala lineal aplica un factor de escalado para
visualizar conjuntamente series de magnitudes diferentes mediante un eje
secundario.

En el grafico logaritmico ambas series comparten el mismo eje
transformado con `scale_y_log10()`, lo que permite comparar tendencias
relativas sin necesidad de doble eje.

La funcion requiere que las credenciales esten disponibles en las
variables de entorno:

- `ala_es_user`

- `ala_es_pw`

## See also

[`galah_call`](https://galah.ala.org.au/R/reference/galah_call.html),
[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html),
[`geom_area`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)

## Examples

``` r
if (FALSE) { # \dontrun{
plots <- crear_plots_evolucion_basisOfRecord()

# Grafico en escala lineal
plots$lineal

# Grafico en escala logaritmica
plots$log

# Datos agregados
head(plots$data)
} # }
```
