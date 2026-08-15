library(httr2)
library(dplyr)
library(purrr)
library(tibble)


# Sistema de alarma para detectar nuevas entidades en registros externos.
#
# Flujo de trabajo:
#   1. Extrae el estado actual de todos los registros externos.
#   2. Compara con una instantanea (snapshot) anterior guardada en disco.
#   3. Genera un informe de diferencias (entidades nuevas o eliminadas).
#   4. Guarda la instantanea actualizada para la proxima comparacion.
#
# Uso tipico (ejecutar periodicamente, p.ej. via cron o GitHub Actions):
#
#   source("inst/scripts/extraer_metadata_ror.R")
#   source("inst/scripts/extraer_metadata_gbif.R")
#   source("inst/scripts/extraer_metadata_grscioll.R")
#   source("inst/scripts/extraer_metadata_indexherbariorum.R")
#   source("inst/scripts/extraer_metadata_obis.R")
#   source("inst/scripts/extraer_metadata_wikidata.R")
#   source("inst/scripts/sistema_alarma.R")
#   informe <- comparar_con_snapshot()
#   cat(formatear_informe_alarma(informe))


# ============================================================
# Rutas de snapshots
# ============================================================

SNAPSHOT_DIR <- file.path("inst", "data", "snapshots")


# ============================================================
# Funciones auxiliares
# ============================================================

#' Obtener IDs actuales de cada registro externo
#'
#' Devuelve una lista nombrada donde cada elemento es un vector de IDs
#' del registro correspondiente.
obtener_ids_actuales <- function(
    ror        = ror_spain,
    gbif       = gbiforg_spain,
    grscioll   = grscioll_spain,
    ih         = indexherbariorum_spain,
    obis       = obis_spain,
    wikidata   = wikidata_spain
) {

  list(
    ror = if (!is.null(ror) && nrow(ror) > 0)
            ror$ror_id else character(),

    gbif_publishers = if (!is.null(gbif) && nrow(gbif) > 0) {
                        gbif |>
                          select(publishingOrg) |>
                          distinct() |>
                          pull(publishingOrg)
                      } else character(),

    grscioll_institutions = if (!is.null(grscioll$instituciones) &&
                                  nrow(grscioll$instituciones) > 0)
                              grscioll$instituciones$grscioll_institution_id else character(),

    grscioll_collections  = if (!is.null(grscioll$colecciones) &&
                                  nrow(grscioll$colecciones) > 0)
                              grscioll$colecciones$grscioll_collection_id else character(),

    indexherbariorum = if (!is.null(ih) && nrow(ih) > 0)
                         ih$ih_id else character(),

    obis = if (!is.null(obis) && nrow(obis) > 0) {
             obis |>
               select(instituteid) |>
               distinct() |>
               pull(instituteid) |>
               as.character()
           } else character(),

    wikidata = if (!is.null(wikidata) && nrow(wikidata) > 0)
                 wikidata$wikidata_id else character()
  )
}


#' Guardar snapshot de IDs actuales
#'
#' @param ids Lista de IDs actuales (resultado de `obtener_ids_actuales()`).
#' @param fecha Fecha del snapshot (por defecto la fecha actual).
#' @param dir  Directorio donde guardar el snapshot.
guardar_snapshot <- function(ids,
                             fecha = Sys.Date(),
                             dir   = SNAPSHOT_DIR) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  ruta <- file.path(dir, paste0("snapshot_", fecha, ".rds"))
  saveRDS(ids, ruta)
  message("Snapshot guardado en: ", ruta)
  invisible(ruta)
}


#' Cargar snapshot mas reciente
#'
#' @param dir Directorio de snapshots.
#' @return Lista de IDs del snapshot mas reciente, o NULL si no existe.
cargar_snapshot_anterior <- function(dir = SNAPSHOT_DIR) {
  archivos <- list.files(dir, pattern = "^snapshot_.*\\.rds$", full.names = TRUE)

  if (length(archivos) == 0) {
    message("No se encontro ningun snapshot anterior.")
    return(NULL)
  }

  # Ordenar por nombre (fecha) y tomar el mas reciente
  archivos_ordenados <- sort(archivos, decreasing = TRUE)
  ruta <- archivos_ordenados[[1]]

  message("Cargando snapshot anterior: ", ruta)
  readRDS(ruta)
}


#' Comparar IDs actuales con snapshot anterior
#'
#' @param ids_actuales  Lista de IDs actuales.
#' @param ids_anteriores Lista de IDs del snapshot anterior.
#' @return Lista con elementos `nuevos` y `eliminados` por registro.
comparar_ids <- function(ids_actuales, ids_anteriores) {

  registros <- names(ids_actuales)

  map(setNames(registros, registros), function(reg) {
    act <- ids_actuales[[reg]]   %||% character()
    ant <- ids_anteriores[[reg]] %||% character()

    list(
      nuevos     = setdiff(act, ant),
      eliminados = setdiff(ant, act)
    )
  })
}


#' Comparar estado actual con snapshot anterior
#'
#' Funcion principal del sistema de alarma. Extrae los IDs actuales,
#' los compara con el snapshot mas reciente y guarda el nuevo snapshot.
#'
#' @param ... Argumentos pasados a `obtener_ids_actuales()`.
#' @param guardar Logico. Si TRUE (por defecto) guarda el nuevo snapshot.
#' @param dir     Directorio de snapshots.
#' @return Lista con los resultados de la comparacion.
comparar_con_snapshot <- function(...,
                                  guardar = TRUE,
                                  dir     = SNAPSHOT_DIR) {

  ids_actuales   <- obtener_ids_actuales(...)
  ids_anteriores <- cargar_snapshot_anterior(dir)

  diferencias <- if (!is.null(ids_anteriores)) {
    comparar_ids(ids_actuales, ids_anteriores)
  } else {
    message("Primera ejecucion: no hay snapshot anterior para comparar.")
    NULL
  }

  if (guardar) {
    guardar_snapshot(ids_actuales, dir = dir)
  }

  list(
    fecha           = Sys.time(),
    ids_actuales    = ids_actuales,
    ids_anteriores  = ids_anteriores,
    diferencias     = diferencias
  )
}


#' Formatear el informe de alarma como texto legible
#'
#' @param informe Resultado de `comparar_con_snapshot()`.
#' @return Cadena de texto con el informe de diferencias.
formatear_informe_alarma <- function(informe) {

  if (is.null(informe$diferencias)) {
    return("Primera ejecucion. Se ha guardado el snapshot inicial. No hay diferencias que reportar.\n")
  }

  lineas <- c(
    paste0("=== INFORME DE ALARMA GBIF.es ==="),
    paste0("Fecha: ", format(informe$fecha, "%Y-%m-%d %H:%M:%S")),
    ""
  )

  hay_cambios <- FALSE

  for (reg in names(informe$diferencias)) {
    nuevos     <- informe$diferencias[[reg]]$nuevos
    eliminados <- informe$diferencias[[reg]]$eliminados

    if (length(nuevos) == 0 && length(eliminados) == 0) next

    hay_cambios <- TRUE

    lineas <- c(lineas,
      paste0("--- ", toupper(reg), " ---"),
      if (length(nuevos) > 0)
        c(paste0("  NUEVOS (", length(nuevos), "):"),
          paste0("    + ", nuevos))
      else
        character(),
      if (length(eliminados) > 0)
        c(paste0("  ELIMINADOS (", length(eliminados), "):"),
          paste0("    - ", eliminados))
      else
        character(),
      ""
    )
  }

  if (!hay_cambios) {
    lineas <- c(lineas, "No se detectaron cambios respecto al snapshot anterior.")
  }

  paste(lineas, collapse = "\n")
}


# ============================================================
# Resumen de recuentos actuales por registro
# ============================================================

#' Mostrar resumen de recuentos actuales por registro
#'
#' @param ids Lista de IDs actuales (resultado de `obtener_ids_actuales()`).
resumen_registros <- function(ids = obtener_ids_actuales()) {

  recuentos <- map_int(ids, length)

  resumen <- tibble(
    registro    = names(recuentos),
    n_entidades = recuentos
  )

  print(resumen)
  invisible(resumen)
}
