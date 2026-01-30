test_that("crear_piechart devuelve un objeto ggplot", {
  
  df_base <- data.frame(
    sector = c("A", "B", "C", "TOTAL"),
    n_recursos = c(50, 30, 20, 100)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  p <- crear_piechart(
    rds_path = tmp,
    categoria = "sector",
    valor = "n_recursos"
  )
  
  expect_s3_class(p, "ggplot")
})


test_that("falla si el RDS no contiene un data.frame", {
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(list(a = 1), tmp)
  
  expect_error(
    crear_piechart(tmp, "sector", "n_recursos")
  )
})


test_that("falla si la columna categoria no existe", {
  
  df_base <- data.frame(
    sector = c("A", "B"),
    n_recursos = c(10, 20)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  expect_error(
    crear_piechart(tmp, "no_existe", "n_recursos")
  )
})


test_that("falla si la columna valor no existe", {
  
  df_base <- data.frame(
    sector = c("A", "B"),
    n_recursos = c(10, 20)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  expect_error(
    crear_piechart(tmp, "sector", "no_existe")
  )
})


test_that("la categoría TOTAL no aparece en los datos del gráfico", {
  
  df_base <- data.frame(
    sector = c("A", "B", "TOTAL"),
    n_recursos = c(40, 60, 100)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  p <- crear_piechart(tmp, "sector", "n_recursos")
  
  expect_false("TOTAL" %in% as.character(p$data$sector))
})


test_that("agrega correctamente categorías repetidas", {
  
  df_rep <- data.frame(
    sector = c("A", "A", "B"),
    n_recursos = c(10, 20, 30)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_rep, tmp)
  
  p <- crear_piechart(tmp, "sector", "n_recursos")
  
  datos <- p$data
  
  expect_equal(
    datos$valor[datos$sector == "A"],
    30
  )
})


test_that("los porcentajes sin redondear suman aproximadamente 100", {
  
  df_base <- data.frame(
    sector = c("A", "B", "C"),
    n_recursos = c(20, 30, 50)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  p <- crear_piechart(tmp, "sector", "n_recursos")
  
  expect_equal(
    sum(p$data$pct_raw),
    100,
    tolerance = 1e-6
  )
})


test_that("las etiquetas contienen el símbolo %", {
  
  df_base <- data.frame(
    sector = c("A", "B"),
    n_recursos = c(25, 75)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  p <- crear_piechart(tmp, "sector", "n_recursos")
  
  expect_true(
    all(grepl("%$", p$data$etiqueta))
  )
})


test_that("la función se ejecuta sin warnings", {
  
  df_base <- data.frame(
    sector = c("A", "B"),
    n_recursos = c(10, 90)
  )
  
  tmp <- tempfile(fileext = ".rds")
  saveRDS(df_base, tmp)
  
  expect_silent(
    crear_piechart(tmp, "sector", "n_recursos")
  )
})
