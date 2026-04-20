# Anhadir metadatos EML y numero de occurrences a una tabla con columna dwca_url

Procesa una tabla que debe contener una columna llamada `dwca_url` con
URLs a archivos ZIP de tipo Darwin Core Archive (DwC-A). Para cada URL:

- descarga el ZIP,

- lee `eml.xml`,

- extrae `title`

- extrae `packageId` y parsea solo la version (por ejemplo `V2.2`),

- extrae `pubDate`,

- lee `meta.xml`,

- localiza el fichero de occurrences a partir de `rowType` y `location`,

- cuenta sus registros restando `ignoreHeaderLines`.

Para mejorar la eficiencia, cada URL unica se procesa una sola vez
aunque aparezca repetida en varias filas.

## Usage

``` r
extract_dwca_metadata(df, progress = TRUE)
```

## Arguments

- df:

  `data.frame` que debe contener una columna llamada `dwca_url`. Puede
  incluir columnas adicionales, como por ejemplo `recurso_fk` o
  `url_ipt`, que se conservarán en la salida.

- progress:

  Si `TRUE`, muestra progreso por consola.

## Value

El mismo `df` de entrada, conservando sus columnas originales y
anhadiendo:

- `eml_title`

- `eml_version`

- `eml_pub_date`

- `eml_occurrences`

- `eml_status`

- `eml_error_message`

Si una URL no puede procesarse correctamente, las columnas extraidas
quedarán como `NA` y el detalle del problema se registrará en
`eml_error_message`.

## Details

Esta funcion asume que:

- la URL del recurso DwC-A está en la columna `dwca_url`

- el titulo está en un nodo `title` de `eml.xml`

- la version está en el atributo `packageId` del nodo raiz de `eml.xml`

- la fecha está en el nodo `pubDate`

- el fichero de occurrences está definido en `meta.xml`

- las lineas de cabecera se indican en el atributo `ignoreHeaderLines`

El conteo de occurrences se realiza en streaming, sin cargar el fichero
completo en memoria.

## Examples

``` r
if (FALSE) { # \dontrun{
out <- extract_dwca_metadata(df)
} # }
```
