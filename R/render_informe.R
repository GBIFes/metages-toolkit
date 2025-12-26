#' Renderiza el informe METAGES 
#'
#' Renderiza el archivo Quarto `informe.qmd` incluido en el paquete \pkg{metagesToolkit} 
#' y genera un informe Word (`.docx`) junto con todos los archivos auxiliares producidos por Quarto.
#'
#' El informe se renderiza en un directorio temporal y, una vez finalizado,
#' todo el contenido generado se copia al directorio de trabajo actual
#' dentro de la carpeta \code{informe_output}, preservando la estructura
#' de subdirectorios.
#'
#'
#' @param overwrite Si \code{TRUE}, elimina y vuelve a crear el directorio
#'   \code{informe_output} si ya existe en el directorio de trabajo.
#'   Si \code{FALSE} y el directorio existe, la funcion lanza un error.
#'
#' @return Crea varias carpetas y archivos de cache, figuras y un documento (`.docx`).
#' 
#' @import quarto
#' 
#' @export

render_informe <- function(overwrite = TRUE) {
  
  # 1. Localizar reports del paquete
  reports_src <- system.file("reports", package = "metagesToolkit")
  if (reports_src == "") {
    stop("No se ha encontrado el directorio 'reports' en el paquete",
         call. = FALSE)
  }
  
  # 2. Crear directorio temporal de render
  tmp_root <- tempfile("metages_render_")
  dir.create(tmp_root, recursive = TRUE)
  
  # Copiar reports completo al temporal
  file.copy(
    from = reports_src,
    to   = tmp_root,
    recursive = TRUE
  )
  
  reports_tmp <- file.path(tmp_root, "reports")
  qmd_tmp <- file.path(reports_tmp, "informe.qmd")
  
  # 3. Renderizar (TODO se genera dentro de reports_tmp)
  quarto::quarto_render(
    input = qmd_tmp,
    output_format = "docx"
  )
  
  # 4. Copiar reports completo a getwd(), sin aplanar
  dst_reports <- file.path(getwd(), "informe_output")
  
  if (dir.exists(dst_reports)) {
    if (!overwrite) {
      stop("El directorio 'informe_output' ya existe y overwrite = FALSE",
           call. = FALSE)
    }
    unlink(dst_reports, recursive = TRUE)
  }
  
  dir.create(dst_reports, recursive = TRUE)
  
  file.copy(
    from = reports_tmp,
    to   = dst_reports,
    recursive = TRUE
  )
  
  invisible(normalizePath(file.path(dst_reports, "informe.docx"),
                          mustWork = FALSE))
}






