test_that("pal_categoria es una paleta válida", {
  
  expect_type(pal_categoria, "character")
  expect_true(!is.null(names(pal_categoria)))
  expect_true(
    all(grepl("^#[0-9A-Fa-f]{6}$", pal_categoria))
  )
})
