# Tabla resumen taxonomico de registros GBIF publicados por Espanha

Genera una tabla resumen con el numero de registros publicados en
GBIF.es, desglosados por reino y acompanhados del numero de clases,
ordenes, familias, generos y especies representadas en dichos registros.

## Usage

``` r
extraer_resumen_taxonomico_gbif(basisOfRecord = NULL)
```

## Arguments

- basisOfRecord:

  Vector de tipos de registro a incluir. Si es `NULL`, no se aplica
  filtro por tipo de registro.

## Value

Un tibble con las siguientes columnas:

- Reino:

  Nombre del reino taxonomico.

- NU+000BA registros:

  numero total de registros publicados.

- NU+000BA clases:

  numero de clases representadas en los registros.

- NU+000BA ordenes:

  numero de ordenes representadas.

- NU+000BA familias:

  numero de familias representadas.

- NU+000BA generos:

  numero de generos representados.

- NU+000BA especies y taxones infraespecificos:

  numero de especies representadas en los registros.

## Details

Los conteos taxonomicos se calculan utilizando facets del endpoint
`/occurrence/count`, por lo que respetan los filtros de pais, estado de
ocurrencia y `basisOfRecord`.

Se adiciona una fila final denominada **Total** con la suma de todas las
metricas numericas.

Ejemplos habituales de valores para `basisOfRecord`:

Especimenes:

    c("PRESERVED_SPECIMEN",
      "MATERIAL_SAMPLE",
      "FOSSIL_SPECIMEN")

Observaciones:

    c("OBSERVATION",
      "HUMAN_OBSERVATION",
      "MACHINE_OBSERVATION")

## Examples

``` r
# Tabla usando todos los registros (sin filtrar por basisOfRecord)
if (FALSE) { # \dontrun{
extraer_resumen_taxonomico_gbif()
} # }

# Solo especimenes
if (FALSE) { # \dontrun{
extraer_resumen_taxonomico_gbif(
  basisOfRecord = c("PRESERVED_SPECIMEN",
                    "MATERIAL_SAMPLE",
                    "FOSSIL_SPECIMEN")
)
} # }

# Solo observaciones humanas
if (FALSE) { # \dontrun{
extraer_resumen_taxonomico_gbif(
  basisOfRecord = "HUMAN_OBSERVATION"
)
} # }
```
