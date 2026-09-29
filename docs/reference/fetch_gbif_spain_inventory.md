# Obtener el inventario de datasets publicados desde Espana en GBIF

Descarga publishers espanoles y datasets con `publishingCountry=ES`.
Consulta ademas el detalle de cada dataset para incluir sus endpoints
`DWC_ARCHIVE` y `EML`. Devuelve tablas normalizadas y respuestas
detalladas de GBIF, sin realizar escrituras ni requerir una conexion con
MetaGES.

## Usage

``` r
fetch_gbif_spain_inventory(page_limit = 300L, request_delay = 0.2)
```

## Arguments

- page_limit:

  Tamano de pagina usado en la API de GBIF.

- request_delay:

  Pausa en segundos entre paginas y bloques de consulta.

## Value

Lista con `publishers`, `datasets`, `raw_publishers` y `raw_datasets`.
