#' Inserta la tabla de colecciones en el informe Word
#'
#' Genera los datos actualizados, aplica el formateo de valores,
#' construye la flextable con hipervinculos e inserta la tabla
#' en el informe Word generado previamente.
#'
#' @param keyword Texto exacto del encabezado donde insertar la tabla.
#'
#' @return Ruta al archivo .docx modificado.
#' @import officer flextable dplyr scales
#' @export
insertar_tabla_colecciones <- function(keyword) {
  
  # 1. Localizar el docx generado por render_informe()
  docx_path <- getOption("metagesToolkit.last_docx")
  if (is.null(docx_path) || !file.exists(docx_path)) {
    stop(
      "No se encuentra un informe renderizado. ",
      "Ejecute primero render_informe().",
      call. = FALSE
    )
  }
  
  # 2. Construir los datos actualizados
  tabla <- extraer_colecciones_mapa()$data |>
    # Hay que anhadir filtro para disciplinas y subdisciplinas
    dplyr::transmute(
      institucion_proyecto,
      url_institucion,
      coleccion_base,
      coleccion_url,
      codigo = collection_code,
      `Localidad (provincia)` = dplyr::if_else(
        town != region,
        paste0(as.character(town), " (", region, ")"),
        as.character(town)
      ),
      `ejemplares_registros_ano` = dplyr::if_else(
        number_of_subunits == 0,
        "-",
        paste0(
          scales::number(
            number_of_subunits,
            big.mark = ".", decimal.mark = ","
          ),
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
          scales::number(
            numberOfRecords,
            big.mark = ".", decimal.mark = ","
          ),
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
        tipo_body == "coleccion" ~ "CB",
        tipo_body == "base de datos" ~ "BD",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::rename("C\u00F3digo" = codigo,
                  "Ejemplares/Registros (a\u00F1o)" = ejemplares_registros_ano,
                  "Registros publicados en GBIF (a\u00F1o)" = registros_gbif_ano) |>
    dplyr::distinct() |> head()
  
  
  # 3. Crear la flextable para que funciones los hipervinculos
  ft <- flextable::flextable(tabla)
  
  ft <- flextable::compose(
    ft,
    part = "body",
    j = "institucion_proyecto",
    value = flextable::as_paragraph(
      flextable::hyperlink_text(
        x   = institucion_proyecto,
        url = url_institucion,
        style = fp_text(
          color = "blue",
          underlined = TRUE
        )
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
        style = fp_text(
          color = "blue",
          underlined = TRUE
        )
      )
    )
  )
  
  ft <- flextable::set_header_labels(
    ft,
    institucion_proyecto = "Instituci\u00F3n / Proyecto",
    coleccion_base       = "Colecci\u00F3n / Base de datos"
  )
  
  ft <- flextable::delete_columns(ft, j = c("url_institucion", "coleccion_url"))
  
  
  

  
  
  #flextable::save_as_docx(ft, path = "test.docx")
  
  
  # 4. Insertar la tabla en el Word final
  
  
  doc <- officer::read_docx(docx_path)
  doc <- officer::cursor_reach(doc, keyword = keyword)
  

  
  # Empezar seccion landscape
  doc <- officer::body_end_section_portrait(doc)
  

  
  doc <- flextable::body_add_flextable(
    doc,
    value = ft,
    align = "center"
  )
  
  # Continuar seccion vertical
  doc <- officer::body_end_section_landscape(doc)
  
  # Guardar
  out_path <- sub("\\.docx$", "_con_tablas_colecciones.docx", docx_path)
  print(doc, target = out_path)
  invisible(out_path)
  
}
