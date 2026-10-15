# Sincronizar GBIF con los monitores MetaGES

Descubre datasets publicados desde Espana, los compara por UUID con
MetaGES y prepara recursos nuevos. Tambien mantiene todos los recursos
publicos de MetaGES vinculados con GBIF, incluidos los publicados fuera
de Espana.

Reutiliza el extractor detallado interno como unica implementacion para
titulo, version, fecha, conteo y fallback DwC-A. La funcion nunca
incorpora recursos ni aplica cambios definitivos sobre
`metages_recurso`; esas acciones pertenecen a los procedimientos SQL
controlados.

## Usage

``` r
run_gbif_spain_workflow(
  con = NULL,
  entorno = c("prod", "test"),
  progress = TRUE,
  request_delay = 0.2,
  max_stale_days = 30,
  force_full = FALSE,
  write = TRUE,
  checked_at = Sys.time()
)
```

## Arguments

- con:

  Conexion DBI existente. Si es `NULL`, se abre una conexion con
  [`conectar_metages()`](https://gbifes.github.io/metages-toolkit/reference/conectar_metages.md)
  y se cierra al terminar el workflow completo.

- entorno:

  Entorno usado cuando `con` es `NULL`: `"prod"` o `"test"`.

- progress:

  Mostrar mensajes de progreso.

- request_delay:

  Pausa en segundos entre paginas o comprobaciones GBIF.

- max_stale_days:

  Antiguedad maxima de un chequeo detallado antes de forzar una
  reconciliacion.

- force_full:

  Si es `TRUE`, vuelve a extraer todos los recursos publicos resolubles
  y disponibles, sean o no espanoles.

- write:

  Si es `FALSE`, ejecuta la lectura y comparacion sin escribir en los
  monitores. Combinado con `force_full=TRUE` sustituye la comparacion
  manual completa anterior.

- checked_at:

  Fecha-hora UTC del run.

## Value

Invisiblemente, lista con inventario normalizado y crudo, resumen,
correspondencias, candidatos, recursos sin identidad GBIF resoluble,
errores de identidad, comparaciones y disponibilidad. `datasets` parte
del inventario externo espanol y separa sus coincidencias publicas y
privadas en MetaGES. `new_candidates` contiene exclusivamente datasets
externos sin ninguna coincidencia interna. `identity_errors` parte de
UUID usados por dos o mas recursos publicos de MetaGES y se enriquece
con el dataset externo espanol cuando existe. `existing_checked` y
`existing_skipped` representan recursos publicos de MetaGES con una
correspondencia externa unica. `endpoint_monitor` contiene los endpoints
detectados que se preparan para completar campos internos vacios.
`unresolved_resources` contiene recursos MetaGES que se excluyeron
porque no pudo obtenerse un UUID desde `uuid`, `url_gbiforg` ni
`url_ipt`.

## Details

Los recursos que solo coinciden con filas privadas se clasifican como
`existing_private` y nunca se tratan como altas. Los privados
manualmente quedan fuera del seguimiento de disponibilidad; los
privatizados por este workflow si se conservan en `availability` para
detectar su reaparicion. Los endpoints GBIF detectados se preparan para
completar `url_ipt` y `url_eml` unicamente cuando esos campos estan
vacios; nunca se sustituyen ni se borran URLs existentes. Con
`write = TRUE`, antes de escribir nuevos candidatos se retiran del
staging las filas no incorporadas cuyo UUID ya exista en MetaGES.
