# Ejecutar el workflow completo de monitorizacion de recursos

Ejecuta el flujo completo de monitorizacion:

1.  abre una conexion con
    [`conectar_metages()`](https://gbifes.github.io/metages-toolkit/reference/conectar_metages.md)

2.  lee recursos publicos desde `metages_recurso`

3.  construye un baseline por recurso usando `metages_provision_recurso`
    y `metages_recurso`

4.  cierra la conexion antes del procesamiento largo

5.  construye `dwca_url` a partir de `url_ipt`

6.  transforma `resource` en `archive` solo cuando `archive` no exista
    ya

7.  llama a
    [`extract_dwca_metadata()`](https://gbifes.github.io/metages-toolkit/reference/extract_dwca_metadata.md)

8.  reabre conexion

9.  actualiza `metages_recurso_monitor`

10. inserta eventos en `metages_recurso_monitor_log`

## Usage

``` r
run_recurso_monitor_workflow(progress = TRUE, checked_at = Sys.time())
```

## Arguments

- progress:

  Si `TRUE`, muestra progreso por consola.

- checked_at:

  Fecha-hora del chequeo. Por defecto
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

## Value

Una lista invisible con:

- `input_df`

- `snapshot_df`

- `current_upsert_df`

- `log_insert_df`

- `comparison_df`
