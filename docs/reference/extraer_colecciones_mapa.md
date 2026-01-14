# Extraer colecciones desde METAGES para mapas

Abre conexión a METAGES (vía
[`conectar_metages()`](https://gbifes.github.io/metages-toolkit/reference/conectar_metages.md)),
ejecuta una consulta (`SELECT * FROM colecciones c`) y devuelve un
data.frame depurado para mapas.

## Usage

``` r
extraer_colecciones_mapa(
  shift = c(5, 6),
  cerrar_conexion = FALSE,
  cerrar_tunel = FALSE
)
```

## Arguments

- shift:

  Vector numérico de longitud 2. Se usa en el procesamiento para
  desplazar los datos de canarias y coincidir con
  [`get_basemap_es()`](https://gbifes.github.io/metages-toolkit/reference/get_basemap_es.md).

- cerrar_conexion:

  Si `TRUE`, cierra la conexión DB al finalizar.

- cerrar_tunel:

  Si `TRUE`, cierra el túnel/proceso al finalizar.

## Value

Invisiblemente, un data.frame/tibble con los datos de colecciones listos
para usar en
[`crear_mapa()`](https://gbifes.github.io/metages-toolkit/reference/crear_mapa.md).
