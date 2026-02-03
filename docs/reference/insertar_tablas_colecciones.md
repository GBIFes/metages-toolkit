# Insertar multiples tablas de colecciones en un informe Word

Inserta secuencialmente varias tablas de colecciones en un informe Word
previamente generado mediante
[`render_informe()`](https://gbifes.github.io/metages-toolkit/reference/render_informe.md),
utilizando distintos encabezados y filtros para cada seccion.

## Usage

``` r
insertar_tablas_colecciones(keywords, filtros)
```

## Arguments

- keywords:

  Vector de caracteres con los encabezados exactos del documento Word
  donde se insertara cada tabla.

- filtros:

  Lista de listas con los criterios de filtrado asociados a cada
  encabezado. Cada elemento debe corresponder a uno de `keywords`.

## Value

Ruta al archivo `.docx` final generado.

## Details

El documento Word se escribe unicamente al final del proceso. La
generacion del archivo puede tardar varios minutos en documentos
grandes, debido a la serializacion completa del contenido.

## Examples

``` r
if (FALSE) { # \dontrun{
insertar_tablas_colecciones(
  keywords = c(
    "Colecciones y bases de datos de invertebrados",
    "Colecciones y bases de datos de vertebrados",
    "Colecciones y bases de datos de invertebrados y vertebrados",
    "Colecciones y bases de datos de plantas",
    "Colecciones y bases de datos de algas",
    "Colecciones y bases de datos de hongos y l\u00EDquenes",
    "Colecciones y bases de datos de bot\u00E1nicas mixtas",
    "Colecciones y bases de datos microbiol\u00F3gicas",
    "Colecciones y bases de datos paleontol\u00F3gicas",
    "Colecciones y bases de datos mixtas"
  ),
  filtros = list(
    list(subdisciplina = "Invertebrados"),
    list(subdisciplina = "Vertebrados"),
    list(subdisciplina = "Invertebrados y vertebrados"),
    list(subdisciplina = "Plantas"),
    list(subdisciplina = "Algas"),
    list(subdisciplina = "Hongos y l\u00EDquenes"),
    list(subdisciplina = "Bot\u00E1nicas mixtas"),
    list(disciplina = "Microbiol\u00F3gica"),
    list(disciplina = "Paleontol\u00F3gica"),
    list(disciplina = "Mixta")
  )
)} # }

```
