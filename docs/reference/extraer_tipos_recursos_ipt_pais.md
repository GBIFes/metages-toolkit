# Numero de juegos de datos por pais publicador divididos por tipo de recurso.

Consulta la API del registro de GBIF para obtener el numero de datasets
publicados por un pais determinado, agrupados por tipo de dataset, junto
con el numero total de registros indexados en GBIF.

## Usage

``` r
extraer_tipos_recursos_ipt_pais(country = "ES")
```

## Arguments

- country:

  Codigo ISO2 del pais publicador (por defecto "ES").

## Value

Un `data.frame` con tres columnas:

- type:

  Tipo de dataset

- n_recursos:

  Numero de datasets

- n_registros:

  Numero total de registros publicados

Incluye una fila final con los totales agregados.

## Details

Los tipos considerados son siempre:

- "Occurrence"

- "Checklist"

- "Sampling Event"

- "Metadata"

La funcion utiliza la API publica del registro de GBIF:
<https://api.gbif.org/v1/dataset/search>

El numero de registros corresponde al campo `recordCount` reportado por
GBIF para cada dataset.

## Examples

``` r
if (FALSE) { # \dontrun{
extraer_tipos_recursos_ipt_pais("ES")
} # }
```
