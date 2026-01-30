#' Paleta categorica para graficos de colecciones y recursos
#'
#' Paleta de colores fija utilizada en graficos categoricos
#' (disciplinas y sectores) del Registro de Colecciones de GBIF.ES.
#'
#' Los colores estan definidos de forma explicita para garantizar
#' consistencia visual entre graficas, independientemente de los datos.
#' 
#' @format Un vector de caracteres nombrado con codigos hexadecimales.
#'
#' @keywords internal
pal_categoria <- c(
  # Disciplinas
  "Zool\u00f3gica"        = "#3B528B",
  "Bot\u00e1nica"         = "#5EC962",
  "Mixta"            = "#ACC72A",
  "Microbiol\u00f3gica"   = "#EB7B33",
  "Paleontol\u00f3gica"   = "#21908C",
  
  # Sectores
  "Acad\u00e9mico"                    = "#5EC962",
  "Administraciones p\u00fablicas"    = "#3B528B",
  "Sector privado"               = "#21908C",
  "Ciencia ciudadana"            = "#ACC72A"
)
