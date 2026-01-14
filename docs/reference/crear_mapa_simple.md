# Mapa METAGES (version simple para uso)

Wrapper de alto nivel sobre
[`crear_mapa()`](https://gbifes.github.io/metages-toolkit/reference/crear_mapa.md)
que fija la infraestructura y expone solo filtros y facet.

## Usage

``` r
crear_mapa_simple(
  tipo_coleccion = NULL,
  disciplina = NULL,
  subdisciplina = NULL,
  publican = NULL,
  facet = NULL
)
```

## Arguments

- tipo_coleccion:

  `colección`, `base de datos` o `NULL`.

- disciplina:

  `Zoológica`, `Botánica`, `Paleontológica`, `Mixta`, `Microbiológica`,
  `Micológica` o `NULL`.

- subdisciplina:

  `Vertebrados`, `Invertebrados`, `Invertebrados y vertebrados`,
  `Plantas`, `Hongos`, `Algas` o `NULL`.

- publican:

  `TRUE`, `FALSE` o `NULL`.

- facet:

  Nombre de columna (string) para facetar o `NULL`.

## Value

Invisiblemente, una lista con:

- plot:

  Objeto `ggplot`.

- data_map:

  data.frame con los datos tras filtros.
