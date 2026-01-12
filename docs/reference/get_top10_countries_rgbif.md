# Top 10 paises con mayor numero de registros en GBIF

Obtiene los 10 paises con mayor numero de registros de ocurrencias en
GBIF a nivel global, usando la API de rgbif. Ademas, calcula la posicion
acumulada historica de cada pais hasta el final de un año previo,
configurable mediante el argumento `years_back`, lo que permite comparar
la situacion actual con el ranking historico.

## Usage

``` r
get_top10_countries_rgbif(years_back = 2)
```

## Arguments

- years_back:

  Entero no negativo que indica cuantos años hacia atras se debe
  calcular el ranking acumulado historico. Por ejemplo:

  - `years_back = 1`: hasta el final del año pasado.

  - `years_back = 2`: hasta el final del año anterior al pasado (valor
    por defecto).

## Value

Un `tibble` con las siguientes columnas:

- `pais`: nombre del pais en español.

- `iso2`: codigo ISO2 del pais

- `count`: numero actual de registros en GBIF.

- `posicion_prev_cum`: posicion en el ranking acumulado historico.

- `count_prev_cum`: numero acumulado de registros hasta el año de
  referencia.

## Details

Los nombres de los paises se devuelven en castellano usando countrycode.

La funcion realiza dos consultas independientes a la API de GBIF:

- Un conteo global actual de registros por pais mediante
  `occ_count_country()`.

- Un conteo acumulado histórico hasta el año de referencia
  (`año_actual - years_back`) utilizando facetas en `occ_search()`.

La posicion historica se calcula a partir del ranking acumulado (orden
descendente de numero de registros).

## Note

Esta funcion realiza llamadas a la API publica de GBIF y requiere
conexion a Internet. En funcion de la carga del servidor, puede tardar
varios segundos o fallar de forma intermitente.

## Examples

``` r
if (FALSE) { # \dontrun{
# Ranking acumulado hasta el final del año pasado
top_countries <- get_top10_countries_rgbif(years_back = 1)

# Ranking acumulado historico mas amplio
top_countries_long <- get_top10_countries_rgbif(years_back = 5)
} # }
```
