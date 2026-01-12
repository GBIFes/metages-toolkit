# Top paises publicadores de datos en GBIF

Obtiene los países con mayor numero de registros publicados en GBIF, en
funcion del pais del publicador (*publishing country*), utilizando
facetas de la API de rgbif.

## Usage

``` r
get_top_publishing_countries_gbif(n = 10, years_back = 2, facet_limit = 300)
```

## Arguments

- n:

  Numero de paises a devolver. Por defecto, 10.

- years_back:

  Entero no negativo que indica cuantos años hacia atras se debe
  calcular el ranking acumulado historico. Por ejemplo:

  - `years_back = 1`: hasta el final del año pasado.

  - `years_back = 2`: hasta el final del año anterior al pasado (valor
    por defecto).

- facet_limit:

  Límite maximo de categorias devueltas por la faceta
  `publishingCountry`. Debe aumentarse si se desea asegurar cobertura
  completa a nivel global.

## Value

Un `tibble` con las siguientes columnas:

- `publishingCountry`: codigo ISO2 del pais publicador.

- `count`: numero de registros publicados.

- `pais_publicador`: nombre del pais en castellano.

## Details

Los nombres de los paises se devuelven en castellano.

La funcion no descarga registros individuales de ocurrencias. Utiliza
exclusivamente facetas, lo que la hace eficiente para resumenes
agregados a gran escala.

## Note

Esta funcion consulta la API publica de GBIF y requiere conexion a
Internet.

## Examples

``` r
if (FALSE) { # \dontrun{
top_publishers <- get_top_publishing_countries_gbif()
top_publishers_20 <- get_top_publishing_countries_gbif(n = 20)
} # }
```
