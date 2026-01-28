test_that("crear_barplot_publicacion devuelve un objeto ggplot con datos válidos", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = c("Botánica", "Zoológica", "TOTAL GENERAL"),
    estado_publicacion = c(
      "Publica en GBIF",
      "No publica en GBIF",
      "Publica en GBIF"
    ),
    total_colecciones = c(10, 5, 15)
  )
  
  saveRDS(df, file.path(tmp, "entidades_per_publican.rds"))
  saveRDS(df, file.path(tmp, "colecciones_per_publican.rds"))
  
  p <- crear_barplot_publicacion(
    rdspath = tmp,
    nivel = "entidades"
  )
  
  expect_s3_class(p, "ggplot")
})


test_that("crear_barplot_publicacion funciona para ambos niveles", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = c("Botánica", "Zoológica"),
    estado_publicacion = c("Publica en GBIF", "No publica en GBIF"),
    total_colecciones = c(10, 5)
  )
  
  saveRDS(df, file.path(tmp, "entidades_per_publican.rds"))
  saveRDS(df, file.path(tmp, "colecciones_per_publican.rds"))
  
  p_ent <- crear_barplot_publicacion(tmp, "entidades")
  p_col <- crear_barplot_publicacion(tmp, "colecciones")
  
  expect_s3_class(p_ent, "ggplot")
  expect_s3_class(p_col, "ggplot")
})


test_that("crear_barplot_publicacion falla si el archivo RDS no existe", {
  
  tmp <- withr::local_tempdir()
  
  expect_error(
    crear_barplot_publicacion(tmp, "entidades"),
    "No se encuentra el archivo RDS"
  )
})


test_that("la etiqueta del eje X cambia según el nivel", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = "Botánica",
    estado_publicacion = "Publica en GBIF",
    total_colecciones = 1
  )
  
  saveRDS(df, file.path(tmp, "entidades_per_publican.rds"))
  saveRDS(df, file.path(tmp, "colecciones_per_publican.rds"))
  
  p_ent <- crear_barplot_publicacion(tmp, "entidades")
  p_col <- crear_barplot_publicacion(tmp, "colecciones")
  
  expect_equal(p_ent$labels$x, "Nº entidades")
  expect_equal(p_col$labels$x, "Nº colecciones y bases de datos")
})


test_that("la fila TOTAL GENERAL se elimina de los datos usados en el gráfico", {
  
  tmp <- withr::local_tempdir()
  
  df <- data.frame(
    disciplina_def = c("Botánica", "TOTAL GENERAL"),
    estado_publicacion = c("Publica en GBIF", "Publica en GBIF"),
    total_colecciones = c(3, 10)
  )
  
  saveRDS(df, file.path(tmp, "entidades_per_publican.rds"))
  
  p <- crear_barplot_publicacion(tmp, "entidades")
  
  expect_false("TOTAL GENERAL" %in% p$data$disciplina_def)
})
