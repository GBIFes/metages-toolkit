# Calcular parámetros de leyenda para mapas

Calcula cuantiles y límites a partir de los recuentos de registros para
construir una leyenda consistente en los mapas.

## Usage

``` r
compute_legend_params(data, probs = c(0.1, 0.4, 0.65, 0.9), signif_digits = 1)
```

## Arguments

- data:

  data.frame que debe contener al menos las columnas
  `number_of_subunits` y `numberOfRecords`.

- probs:

  Vector de probabilidades para calcular cuantiles.

- signif_digits:

  Número de dígitos significativos para etiquetas.

## Value

Invisiblemente, una lista con:

- mybreaks:

  Vector numérico de cortes.

- limits:

  Vector numérico de longitud 2 (min, max).

- probs:

  El vector `probs` usado.
