#' Renderiza el informe METAGES 
#'
#' Renderiza el archivo Quarto `informe.qmd` incluido en el paquete.
#'
#' @return Crea varias carpetas y archivos de cache, figuras y un documento .docx.
#' 
#' @import quarto
#' 
#' @export

render_informe <- function() {
    quarto_render(
        #input = normalizePath("inst/reports/informe.qmd"),   # para DEV
        input = system.file("reports", "informe.qmd", package = "metagesToolkit"),
        output_format = "docx"
        ) |> 
    invisible()
}





