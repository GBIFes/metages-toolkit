test_that("crear_barplot_colecciones_por_anno devuelve un objeto ggplot", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = c("TOTAL GENERAL", "TOTAL GENERAL"),
    fecha_alta_coleccion = c(2000, 2001),
    total_colecciones = as.integer(c(5, 3)),
    acumulado = c(5, 8)
  )
  
  saveRDS(df, file.path(tmp, "colecciones_per_anno.rds"))
  
  p <- crear_barplot_colecciones_por_anno(rdspath = tmp)
  
  expect_s3_class(p, "ggplot")
})


test_that("solo se usan filas con disciplina_def == TOTAL GENERAL", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = c("Botánica", "TOTAL GENERAL"),
    fecha_alta_coleccion = c(2000, 2000),
    total_colecciones = c(10, 5),
    acumulado = c(10, 5)
  )
  
  saveRDS(df, file.path(tmp, "colecciones_per_anno.rds"))
  
  p <- crear_barplot_colecciones_por_anno(rdspath = tmp)
  
  expect_true(all(p$data$disciplina_def == "TOTAL GENERAL"))
})


test_that("las columnas numéricas se convierten correctamente a numeric", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = "TOTAL GENERAL",
    fecha_alta_coleccion = 2005,
    total_colecciones = bit64::as.integer64(7),
    acumulado = bit64::as.integer64(20)
  )
  
  saveRDS(df, file.path(tmp, "colecciones_per_anno.rds"))
  
  p <- crear_barplot_colecciones_por_anno(rdspath = tmp)
  
  expect_type(p$data$valor, "double")
})


test_that("el eje X contiene solo años múltiplos de 5 en los breaks", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = "TOTAL GENERAL",
    fecha_alta_coleccion = 1999:2006,
    total_colecciones = rep(1, 8),
    acumulado = seq_len(8)
  )
  
  saveRDS(df, file.path(tmp, "colecciones_per_anno.rds"))
  
  p <- crear_barplot_colecciones_por_anno(rdspath = tmp)
  
  x_breaks <- p$scales$get_scales("x")$breaks(levels(p$data$x))
  
  expect_true(all(as.numeric(x_breaks) %% 5 == 0))
})


test_that("el gráfico contiene exactamente dos series", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = "TOTAL GENERAL",
    fecha_alta_coleccion = c(2000, 2005),
    total_colecciones = c(2, 3),
    acumulado = c(2, 5)
  )
  
  saveRDS(df, file.path(tmp, "colecciones_per_anno.rds"))
  
  p <- crear_barplot_colecciones_por_anno(rdspath = tmp)
  
  expect_setequal(
    unique(p$data$tipo),
    c("acumulado", "total_colecciones")
  )
})
