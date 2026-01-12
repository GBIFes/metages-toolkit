# Obtener basemap de España (con Canarias desplazadas)

Descarga geometrías de países vecinos y España con `giscoR`, recorta y
desplaza Canarias para crear un basemap “compacto” para mapas.

## Usage

``` r
get_basemap_es(shift = c(5, 6))
```

## Arguments

- shift:

  Vector numérico de longitud 2 con el desplazamiento aplicado a
  Canarias (x, y).

## Value

Invisiblemente, una lista con:

- vecinos:

  Objeto sf con países vecinos.

- ES_fixed:

  Objeto sf con España (Península+Canarias desplazadas).

- bb_fixed:

  Bounding box
  ([`sf::st_bbox`](https://r-spatial.github.io/sf/reference/st_bbox.html))
  de `ES_fixed`.

- bb_can:

  Bounding box
  ([`sf::st_bbox`](https://r-spatial.github.io/sf/reference/st_bbox.html))
  de Canarias desplazadas.

- shift:

  El vector `shift` usado para desplazar canarias.
