# Crear flextable de colecciones

Convierte una tabla de colecciones en un objeto `flextable`, adicionando
hipervinculos en las columnas de institucion y coleccion, ajustando las
cabeceras y eliminando columnas auxiliares no visibles.

## Usage

``` r
crear_flextable_colecciones(tabla)
```

## Arguments

- tabla:

  Un `data.frame` devuelto por
  [`crear_tabla_colecciones()`](https://gbifes.github.io/metages-toolkit/reference/crear_tabla_colecciones.md).

## Value

Un objeto `flextable` listo para ser insertado en un documento Word.
