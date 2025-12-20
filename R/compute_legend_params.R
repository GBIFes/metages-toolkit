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








