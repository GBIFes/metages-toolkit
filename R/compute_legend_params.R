#' Calcular parámetros de leyenda para mapas
#'
#' Calcula cuantiles y límites a partir de los recuentos de registros para
#' construir una leyenda consistente en los mapas.
#'
#'
#' @param data data.frame que debe contener al menos las columnas
#'   `number_of_subunits` y `numberOfRecords`.
#' @param probs Vector de probabilidades para calcular cuantiles.
#' @param signif_digits Número de dígitos significativos para etiquetas.
#'
#' @return Invisiblemente, una lista con:
#' \describe{
#'   \item{mybreaks}{Vector numérico de cortes.}
#'   \item{limits}{Vector numérico de longitud 2 (min, max).}
#'   \item{probs}{El vector `probs` usado.}
#' }
#'
#' @import dplyr
#' @importFrom stats quantile
#'
#' @keywords internal

compute_legend_params <- function(data,
                                  probs = c(.1, .4, .65, .9),
                                  signif_digits = 1) {
  
  data_4_legend <- tibble(records = c(data$number_of_subunits, data$numberOfRecords)) %>%
                   filter(records > 0)
  
  summary(data_4_legend$records)
  
  mybreaks <- quantile(data_4_legend$records,
                       probs, 
                       na.rm = TRUE) %>%
    signif(signif_digits) %>%
    as.numeric()
  
  
  limits <- range(data_4_legend$records, na.rm = TRUE)
  

  return(invisible(list(
    mybreaks = mybreaks,
    limits = limits,
    probs  = probs
  )))
}








