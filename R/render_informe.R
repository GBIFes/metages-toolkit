

render_informe <- function() {
  quarto::quarto_render(
    input = normalizePath("inst/reports/informe.qmd"),
    output_format = "docx"
  )
}





