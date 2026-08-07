# Extraer metadatos de recursos MetaGES mediante GBIF

Consulta el registro y el indice de ocurrencias de GBIF. Cada valor de
`dwca_url` puede ser una URL al DwC-A, un UUID de dataset de GBIF o una
URL de dataset de GBIF.

Las entradas unicas se consultan una sola vez. Para las URLs DwC-A, la
funcion busca el dataset en GBIF y comprueba que su endpoint
`DWC_ARCHIVE` coincida con la URL o con el identificador `r` del recurso
IPT.

## Usage

``` r
extract_gbif_metadata(df, progress = TRUE)
```

## Arguments

- df:

  `data.frame` que debe contener una columna llamada `dwca_url`. Puede
  contener `tipo_recurso_id`; los valores 223, 224 y 225 activan el
  fallback selectivo al DwC-A cuando GBIF devuelve cero occurrences. Las
  demas columnas se conservan sin cambios.

- progress:

  Si `TRUE`, muestra progreso por consola.

## Value

El mismo `df` de entrada, con las columnas adicionales `eml_title`,
`eml_version`, `eml_pub_date`, `eml_occurrences`, `eml_status` y
`eml_error_message`.

## Details

La version se obtiene primero del registro JSON de GBIF. Solo si no esta
disponible se localiza el documento EML fuente registrado en GBIF y se
extrae su atributo `packageId`.

Cuando GBIF devuelve cero occurrences, los tipos 223 y 224 cuentan el
rowType Occurrence del DwC-A y el tipo 225 cuenta el rowType Taxon. El
tipo 226 y los demas tipos conservan el cero de GBIF.

`eml_occurrences` representa los registros actualmente indexados por
GBIF. Por ello puede diferir temporalmente del numero de filas del DwC-A
publicado.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(
  dwca_url = "https://www.gbif.org/dataset/837381f4-f762-11e1-a439-00145eb45e9a"
)
extract_gbif_metadata(df)
} # }
```
