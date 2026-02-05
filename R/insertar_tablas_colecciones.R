#' Crear tabla de colecciones filtrada
#'
#' Construye una tabla de colecciones y bases de datos a partir de los datos
#' devueltos por \code{extraer_colecciones_mapa()}, aplicando filtros opcionales
#' por disciplina y/o subdisciplina. La tabla resultante esta preparada para
#' su uso posterior en una \code{flextable}.
#'
#' @param filtro Lista con criterios de filtrado. Puede contener los elementos
#'   \code{disciplina} y/o \code{subdisciplina}, cuyos valores deben coincidir
#'   exactamente con los existentes en los datos.
#' @param driver Nombre del driver ODBC Unicode a utilizar. Se pasa internamente
#'   a las funciones de acceso a METAGES.
#'
#' @return Un \code{data.frame} con las columnas transformadas, formateadas
#'   y listas para su visualizacion en una tabla.
#'
#' @details
#' Esta funcion no realiza ninguna operacion de entrada/salida ni modifica
#' documentos Word. Su unica responsabilidad es la preparacion de los datos.
#'
#' @import dplyr
#' @import scales 
#'
#' @export
crear_tabla_colecciones <- function(filtro = list(), driver = NULL) {
  
  datos <- extraer_colecciones_mapa(odbc_driver = driver)$data
  
  if (!is.null(filtro$disciplina)) {
    datos <- dplyr::filter(datos, disciplina_def == filtro$disciplina)
  }
  
  if (!is.null(filtro$subdisciplina)) {
    datos <- dplyr::filter(datos, disciplina_subtipo_def == filtro$subdisciplina)
  }
  
  datos |>
    dplyr::transmute(
      institucion_proyecto,
      url_institucion,
      coleccion_base,
      coleccion_url,
      codigo = collection_code,
      `Localidad (provincia)` = dplyr::if_else(
        as.character(town) != as.character(region),
        paste0(as.character(town), " (", as.character(region), ")"),
        as.character(town)
      ),
      ejemplares_registros_ano = dplyr::if_else(
        number_of_subunits == 0,
        "-",
        paste0(
          scales::number(number_of_subunits, big.mark = ".", decimal.mark = ","),
          " (",
          pmax(
            ultima_actualizacion_coleccion,
            fecha_alta_coleccion,
            na.rm = TRUE
          ),
          ")"
        )
      ),
      registros_gbif_ano = dplyr::if_else(
        is.na(numberOfRecords),
        "-",
        paste0(
          scales::number(numberOfRecords, big.mark = ".", decimal.mark = ","),
          " (",
          ultima_actualizacion_recursos,
          ")"
        )
      ),
      `Informat.` = dplyr::if_else(
        percent_database == 0 | is.na(percent_database),
        "-",
        paste0(percent_database, "%")
      ),
      `Georref.` = dplyr::if_else(
        percent_georref == 0 | is.na(percent_georref),
        "-",
        paste0(percent_georref, "%")
      ),
      Tipo = dplyr::case_when(
        tipo_body == "coleccion"     ~ "CB",
        tipo_body == "base de datos" ~ "BD"
      )
    ) |>
    dplyr::rename_with(~ c("Ejemplares/Registros (a\u00F1o)",
                           "Registros publicados en GBIF (a\u00F1o)"),
                       .cols = c(ejemplares_registros_ano,
                                 registros_gbif_ano)) |>
    dplyr::distinct()
}



#' Crear flextable de colecciones
#'
#' Convierte una tabla de colecciones en un objeto \code{flextable}, adicionando
#' hipervinculos en las columnas de institucion y coleccion, ajustando las
#' cabeceras y eliminando columnas auxiliares no visibles.
#'
#' @param tabla Un \code{data.frame} devuelto por
#'   \code{crear_tabla_colecciones()}.
#'
#' @return Un objeto \code{flextable} listo para ser insertado en un documento Word.
#'
#' @import flextable 
#' @import officer 
#'
#' @export
crear_flextable_colecciones <- function(tabla) {
  
  ft <- flextable::flextable(tabla)
  
  ft <- flextable::compose(
    ft,
    part = "body",
    j = "institucion_proyecto",
    value = flextable::as_paragraph(
      flextable::hyperlink_text(
        x   = institucion_proyecto,
        url = url_institucion,
        style = officer::fp_text(color = "blue", underlined = TRUE)
      )
    )
  )
  
  ft <- flextable::compose(
    ft,
    part = "body",
    j = "coleccion_base",
    value = flextable::as_paragraph(
      flextable::hyperlink_text(
        x   = coleccion_base,
        url = coleccion_url,
        style = officer::fp_text(color = "blue", underlined = TRUE)
      )
    )
  )
  
  ft |>
    flextable::set_header_labels(
      institucion_proyecto = "Instituci\u00F3n / Proyecto",
      coleccion_base       = "Colecci\u00F3n / Base de datos"
    ) |>
    flextable::delete_columns(c("url_institucion", "coleccion_url"))
}



#' Insertar una tabla en un documento Word
#'
#' Inserta una flextable en un documento Word ya cargado, posicionandola en el
#' encabezado indicado y gestionando el cambio de secciones entre orientacion
#' vertical y horizontal.
#'
#' @param doc Objeto \code{rdocx} de \pkg{officer}.
#' @param keyword Texto exacto del encabezado donde se insertara la tabla.
#' @param ft Objeto \code{flextable} a insertar.
#'
#' @return El objeto \code{rdocx} modificado.
#'
#' @import officer 
#' @import flextable 
#'
#' @export
insertar_tabla_en_doc <- function(doc, keyword, ft) {
  
  doc <- officer::cursor_reach(doc, keyword = keyword)
  doc <- officer::body_end_section_portrait(doc)
  
  doc <- flextable::body_add_flextable(
    doc,
    value = ft,
    align = "center"
  )
  
  officer::body_end_section_landscape(doc)
}



#' Insertar multiples tablas de colecciones en un informe Word
#'
#' Inserta secuencialmente varias tablas de colecciones en un informe Word
#' previamente generado mediante \code{render_informe()}, utilizando distintos
#' encabezados y filtros para cada seccion.
#'
#' @param keywords Vector de caracteres con los encabezados exactos del documento
#'   Word donde se insertara cada tabla.
#' @param filtros Lista de listas con los criterios de filtrado asociados a cada
#'   encabezado. Cada elemento debe corresponder a uno de \code{keywords}.
#' @param driver Nombre del driver ODBC Unicode a utilizar.
#'   Se pasa a todas las llamadas internas de acceso a METAGES.

#'
#' @return Ruta al archivo \code{.docx} final generado.
#'
#' @details
#' El documento Word se escribe unicamente al final del proceso. La generacion
#' del archivo puede tardar varios minutos en documentos grandes, debido a la
#' serializacion completa del contenido.
#'
#'
#' @examples
#' \dontrun{
#' insertar_tablas_colecciones(
#'   keywords = c(
#'     "Colecciones y bases de datos de invertebrados",
#'     "Colecciones y bases de datos de vertebrados",
#'     "Colecciones y bases de datos de invertebrados y vertebrados",
#'     "Colecciones y bases de datos de plantas",
#'     "Colecciones y bases de datos de algas",
#'     "Colecciones y bases de datos de hongos y l\u00EDquenes",
#'     "Colecciones y bases de datos de bot\u00E1nicas mixtas",
#'     "Colecciones y bases de datos microbiol\u00F3gicas",
#'     "Colecciones y bases de datos paleontol\u00F3gicas",
#'     "Colecciones y bases de datos mixtas"
#'   ),
#'   filtros = list(
#'     list(subdisciplina = "Invertebrados"),
#'     list(subdisciplina = "Vertebrados"),
#'     list(subdisciplina = "Invertebrados y vertebrados"),
#'     list(subdisciplina = "Plantas"),
#'     list(subdisciplina = "Algas"),
#'     list(subdisciplina = "Hongos y l\u00EDquenes"),
#'     list(subdisciplina = "Bot\u00E1nicas mixtas"),
#'     list(disciplina = "Microbiol\u00F3gica"),
#'     list(disciplina = "Paleontol\u00F3gica"),
#'     list(disciplina = "Mixta")
#'   )
#' )}
#'
#'
#' @import officer 
#'
#' @export
insertar_tablas_colecciones <- function(keywords, filtros, driver = NULL) {
  
  stopifnot(length(keywords) == length(filtros))
  
  docx_path <- getOption("metagesToolkit.last_docx")
  if (is.null(docx_path) || !file.exists(docx_path)) {
    stop("Ejecute primero render_informe()", call. = FALSE)
  }
  
  doc <- officer::read_docx(docx_path)
  
  for (i in seq_along(keywords)) {
    message(paste0("Insertando tabla de ", keywords[[i]]))
    
    tabla <- crear_tabla_colecciones(filtros[[i]], 
                                     driver = driver)
    if (nrow(tabla) == 0) next
    
    ft  <- crear_flextable_colecciones(tabla)
    doc <- insertar_tabla_en_doc(doc, keywords[[i]], ft)
  }
  
  out_path <- sub("\\.docx$", "_tablas_colecciones.docx", docx_path)
  
  message("Generando documento Word (puede tardar varios minutos)...")
  print(doc, target = out_path)
  
  invisible(out_path)
}

