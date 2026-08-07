# Comparar snapshot nuevo con baseline de referencia

Compara un snapshot nuevo extraido desde GBIF, con los fallbacks
necesarios al DwC-A, contra el baseline incluido en `snapshot_df`.

Se comparan exactamente estos cuatro campos:

- titulo

- version

- fecha

- numero de occurrences

## Usage

``` r
compare_recurso_monitor_snapshot(snapshot_df, checked_at = Sys.time())
```

## Arguments

- snapshot_df:

  `data.frame` con al menos las columnas: `recurso_fk`, `tipo_recurso`,
  `eml_title`, `eml_version`, `eml_pub_date`, `eml_occurrences`,
  `eml_status`, `eml_error_message`, `baseline_reference_date`,
  `baseline_version`, `baseline_occurrences`, `baseline_title`.

- checked_at:

  Fecha-hora del chequeo. Por defecto
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

Una lista con tres elementos:

- `current_upsert_df`

- `log_insert_df`

- `comparison_df`
