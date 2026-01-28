# Crear mapa de colecciones METAGES

Genera un mapa con puntos sobre un basemap, aplicando filtros opcionales
y un facet opcional. Devuelve tanto el `ggplot` como los datos
filtrados.

## Usage

``` r
crear_mapa(
  data = data,
  basemap,
  legend_params = NULL,
  tipo_coleccion = NULL,
  disciplina = NULL,
  subdisciplina = NULL,
  publican = NULL,
  facet = NULL
)
```

## Arguments

- data:

  data.frame con las columnas necesarias para el mapa. Se genera
  automaticamente con
  [`extraer_colecciones_mapa()`](https://gbifes.github.io/metages-toolkit/reference/extraer_colecciones_mapa.md)

- basemap:

  Lista devuelta por
  [`get_basemap_es()`](https://gbifes.github.io/metages-toolkit/reference/get_basemap_es.md).

- legend_params:

  Lista de parametros de leyenda. Si `NULL`, se calcula con
  `compute_legend_params(data)`.

- tipo_coleccion:

  Uno de `coleccion`, `base de datos` o `NULL`.

- disciplina:

  Uno de `Zool\u00F3gica`, `Bot\u00E1nica`, `Paleontol\u00F3gica`,
  `Mixta`, `Microbiol\u00F3gica` o `NULL`.

- subdisciplina:

  Uno de `Vertebrados`, `Invertebrados`, `Invertebrados y vertebrados`,
  `Plantas`, `Hongos y l\u00EDquenes`, `Algas`, `Bot\u00E1nicas mixtas`
  o `NULL`.

- publican:

  Uno de `TRUE`, `FALSE` o `NULL`.

- facet:

  Nombre de columna (string) para facetar o `NULL`.

## Value

Invisiblemente, una lista con:

- plot:

  Objeto `ggplot`.

- data_map:

  data.frame con los datos tras filtros.

## Details

La funcion asume que los datos de entrada contienen coordenadas
geograficas y metricas asociadas a colecciones.
