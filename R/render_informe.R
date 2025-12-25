#' Renderiza el informe METAGES 
#'
#' Renderiza el archivo Quarto `informe.qmd` incluido en el paquete.
#'
#' @return Crea varias carpetas y archivos de cache, figuras y un documento .docx.
#' 
#' @import quarto
#' 
#' @export

render_informe <- function(output_file = "informe.docx",
                           overwrite = TRUE) {
  
  
  qmd <- system.file("reports", "informe.qmd", package = "metagesToolkit")
  out_dir <- dirname(qmd)
  out_src <- file.path(out_dir, output_file)
  out_dst <- file.path(getwd(), output_file)
  
  quarto_render(
    input = qmd,
    output_format = "docx"
  )
  
  if (file.exists(out_dst) && overwrite) {
    unlink(out_dst)
  }
  
  file.rename(out_src, out_dst)
  
  invisible(normalizePath(out_dst, mustWork = FALSE))
}





