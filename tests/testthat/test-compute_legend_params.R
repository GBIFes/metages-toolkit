test_that("compute_legend_params devuelve una lista con la estructura esperada", {
  
  res <- compute_legend_params(test_data)
  
  expect_type(res, "list")
  expect_named(res, c("mybreaks", "limits", "probs"))
})



test_that("compute_legend_params devuelve tipos correctos", {
  
  res <- compute_legend_params(test_data)
  
  expect_type(res$mybreaks, "double")
  expect_length(res$mybreaks, 4)
  
  expect_type(res$limits, "double")
  expect_length(res$limits, 2)
  
  expect_equal(res$probs, c(.1, .4, .65, .9))
})



test_that("compute_legend_params ignora valores <= 0", {
  
  data_bad <- test_data
  data_bad$number_of_subunits <- c(0, -1, data_bad$number_of_subunits[-(1:2)])
  
  res <- compute_legend_params(data_bad)
  
  expect_true(all(res$limits > 0))
})



test_that("compute_legend_params respeta probs personalizados", {
  
  p <- c(0.25, 0.5, 0.75)
  
  res <- compute_legend_params(test_data, probs = p)
  
  expect_equal(res$probs, p)
  expect_length(res$mybreaks, length(p))
})



test_that("compute_legend_params aplica signif_digits", {
  
  res1 <- compute_legend_params(test_data, signif_digits = 1)
  res2 <- compute_legend_params(test_data, signif_digits = 3)
  
  expect_false(identical(res1$mybreaks, res2$mybreaks))
})

