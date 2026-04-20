testthat::test_that("extract_dwca_metadata() falla si falta dwca_url", {
  df <- data.frame(x = 1:3)
  
  testthat::expect_error(
    extract_dwca_metadata(df, progress = FALSE),
    "La columna 'dwca_url' no existe en `df`."
  )
})

testthat::test_that("extract_dwca_metadata() devuelve columnas vacías si no hay URLs válidas", {
  df <- data.frame(
    id = 1:4,
    dwca_url = c(NA, "", "   ", NA_character_),
    stringsAsFactors = FALSE
  )
  
  out <- extract_dwca_metadata(df, progress = FALSE)
  
  testthat::expect_equal(nrow(out), 4L)
  testthat::expect_true(all(c(
    "eml_title",
    "eml_version",
    "eml_pub_date",
    "eml_occurrences",
    "eml_status",
    "eml_error_message"
  ) %in% names(out)))
  
  testthat::expect_true(all(is.na(out$eml_title)))
  testthat::expect_true(all(is.na(out$eml_version)))
  testthat::expect_true(all(is.na(out$eml_pub_date)))
  testthat::expect_true(all(is.na(out$eml_occurrences)))
  testthat::expect_true(all(is.na(out$eml_status)))
  testthat::expect_true(all(is.na(out$eml_error_message)))
})

testthat::test_that("extract_dwca_metadata() extrae title, version, pubDate y occurrences correctamente", {
  td <- withr::local_tempdir()
  
  dir.create(file.path(td, "dwca", "data"), recursive = TRUE)
  
  eml_text <- paste0(
    '<eml:eml xmlns:eml="eml://ecoinformatics.org/eml-2.1.1" packageId="foo_v2.3">',
    '<dataset>',
    '<title>  Mi dataset de prueba  </title>',
    '<pubDate>2024-01-15</pubDate>',
    '</dataset>',
    '</eml:eml>'
  )
  
  meta_text <- paste0(
    '<archive xmlns="http://rs.tdwg.org/dwc/text/">',
    '<core rowType="http://rs.tdwg.org/dwc/terms/Occurrence" ignoreHeaderLines="1">',
    '<files><location>data/occurrence.txt</location></files>',
    '</core>',
    '</archive>'
  )
  
  occ_lines <- c(
    "id\tname",
    "1\ta",
    "2\tb",
    "3\tc"
  )
  
  writeLines(eml_text, file.path(td, "dwca", "eml.xml"), useBytes = TRUE)
  writeLines(meta_text, file.path(td, "dwca", "meta.xml"), useBytes = TRUE)
  writeLines(occ_lines, file.path(td, "dwca", "data", "occurrence.txt"), useBytes = TRUE)
  
  old_wd <- getwd()
  setwd(file.path(td, "dwca"))
  on.exit(setwd(old_wd), add = TRUE)
  
  zip_path <- file.path(td, "dwca_test.zip")
  utils::zip(
    zipfile = zip_path,
    files = c("eml.xml", "meta.xml", "data/occurrence.txt")
  )
  
  file_url <- paste0("file://", normalizePath(zip_path, winslash = "/"))
  
  df <- data.frame(
    recurso_fk = 1L,
    dwca_url = file_url,
    stringsAsFactors = FALSE
  )
  
  out <- extract_dwca_metadata(df, progress = FALSE)
  
  testthat::expect_equal(nrow(out), 1L)
  testthat::expect_equal(out$eml_title, "Mi dataset de prueba")
  testthat::expect_equal(out$eml_version, "V2.3")
  testthat::expect_equal(out$eml_pub_date, "2024-01-15")
  testthat::expect_equal(out$eml_occurrences, 3L)
  testthat::expect_equal(out$eml_status, "ok")
  testthat::expect_true(is.na(out$eml_error_message))
})

testthat::test_that("extract_dwca_metadata() encuentra occurrence por sufijo de ruta y usa ignoreHeaderLines=0 si falta", {
  td <- withr::local_tempdir()
  
  dir.create(file.path(td, "dwca", "nested"), recursive = TRUE)
  
  eml_text <- paste0(
    '<eml packageId="abcV10">',
    '<dataset>',
    '<title>Otro dataset</title>',
    '<pubDate>2023-12-31</pubDate>',
    '</dataset>',
    '</eml>'
  )
  
  meta_text <- paste0(
    '<archive xmlns="http://rs.tdwg.org/dwc/text/">',
    '<core rowType="http://rs.tdwg.org/dwc/terms/Occurrence">',
    '<files><location>occurrence.txt</location></files>',
    '</core>',
    '</archive>'
  )
  
  occ_lines <- c(
    "1\ta",
    "2\tb",
    "3\tc"
  )
  
  writeLines(eml_text, file.path(td, "dwca", "eml.xml"), useBytes = TRUE)
  writeLines(meta_text, file.path(td, "dwca", "meta.xml"), useBytes = TRUE)
  writeLines(occ_lines, file.path(td, "dwca", "nested", "occurrence.txt"), useBytes = TRUE)
  
  old_wd <- getwd()
  setwd(file.path(td, "dwca"))
  on.exit(setwd(old_wd), add = TRUE)
  
  zip_path <- file.path(td, "dwca_suffix.zip")
  utils::zip(
    zipfile = zip_path,
    files = c("eml.xml", "meta.xml", "nested/occurrence.txt")
  )
  
  file_url <- paste0("file://", normalizePath(zip_path, winslash = "/"))
  
  df <- data.frame(dwca_url = file_url, stringsAsFactors = FALSE)
  out <- extract_dwca_metadata(df, progress = FALSE)
  
  testthat::expect_equal(out$eml_title, "Otro dataset")
  testthat::expect_equal(out$eml_version, "V10")
  testthat::expect_equal(out$eml_pub_date, "2023-12-31")
  testthat::expect_equal(out$eml_occurrences, 3L)
  testthat::expect_equal(out$eml_status, "ok")
})

testthat::test_that("extract_dwca_metadata() procesa cada URL única una sola vez", {
  td <- withr::local_tempdir()
  
  dir.create(file.path(td, "dwca"), recursive = TRUE)
  
  writeLines(
    c(
      '<eml packageId="xV1.0"><dataset><title>T</title><pubDate>2024-01-01</pubDate></dataset></eml>'
    ),
    file.path(td, "dwca", "eml.xml"),
    useBytes = TRUE
  )
  
  writeLines(
    c(
      '<archive xmlns="http://rs.tdwg.org/dwc/text/">',
      '<core rowType="http://rs.tdwg.org/dwc/terms/Occurrence" ignoreHeaderLines="1">',
      '<files><location>occurrence.txt</location></files>',
      '</core>',
      '</archive>'
    ),
    file.path(td, "dwca", "meta.xml"),
    useBytes = TRUE
  )
  
  writeLines(
    c("id", "1", "2"),
    file.path(td, "dwca", "occurrence.txt"),
    useBytes = TRUE
  )
  
  old_wd <- getwd()
  setwd(file.path(td, "dwca"))
  on.exit(setwd(old_wd), add = TRUE)
  
  zip_path <- file.path(td, "dwca_unique.zip")
  utils::zip(
    zipfile = zip_path,
    files = c("eml.xml", "meta.xml", "occurrence.txt")
  )
  
  file_url <- paste0("file://", normalizePath(zip_path, winslash = "/"))
  
  n_downloads <- 0L
  
  testthat::local_mocked_bindings(
    download.file = function(url, destfile, mode = "wb", quiet = TRUE, ...) {
      n_downloads <<- n_downloads + 1L
      src <- sub("^file://", "", url)
      ok <- file.copy(src, destfile, overwrite = TRUE)
      if (!ok) stop("No se pudo copiar el ZIP local")
      invisible(0)
    },
    .package = "utils"
  )
  
  df <- data.frame(
    id = 1:3,
    dwca_url = c(file_url, file_url, paste0("  ", file_url, "  ")),
    stringsAsFactors = FALSE
  )
  
  out <- extract_dwca_metadata(df, progress = FALSE)
  
  testthat::expect_equal(n_downloads, 1L)
  testthat::expect_equal(nrow(out), 3L)
  testthat::expect_true(all(out$eml_occurrences == 2L))
})

testthat::test_that("extract_dwca_metadata() registra error por URL sin interrumpir el procesamiento global", {
  bad_url <- "file:///ruta/que/no/existe.zip"
  
  df <- data.frame(
    id = 1L,
    dwca_url = bad_url,
    stringsAsFactors = FALSE
  )
  
  out <- extract_dwca_metadata(df, progress = FALSE)
  
  testthat::expect_equal(out$eml_status, "error")
  testthat::expect_true(is.na(out$eml_title))
  testthat::expect_true(is.na(out$eml_version))
  testthat::expect_true(is.na(out$eml_pub_date))
  testthat::expect_true(is.na(out$eml_occurrences))
  testthat::expect_true(!is.na(out$eml_error_message))
})

testthat::test_that("extract_dwca_metadata() preserva columnas originales del input", {
  td <- withr::local_tempdir()
  
  dir.create(file.path(td, "dwca"), recursive = TRUE)
  
  writeLines(
    '<eml packageId="pkgV1"><dataset><title>X</title><pubDate>2024-02-02</pubDate></dataset></eml>',
    file.path(td, "dwca", "eml.xml"),
    useBytes = TRUE
  )
  
  writeLines(
    c(
      '<archive xmlns="http://rs.tdwg.org/dwc/text/">',
      '<core rowType="http://rs.tdwg.org/dwc/terms/Occurrence" ignoreHeaderLines="1">',
      '<files><location>occurrence.txt</location></files>',
      '</core>',
      '</archive>'
    ),
    file.path(td, "dwca", "meta.xml"),
    useBytes = TRUE
  )
  
  writeLines(
    c("h", "1"),
    file.path(td, "dwca", "occurrence.txt"),
    useBytes = TRUE
  )
  
  old_wd <- getwd()
  setwd(file.path(td, "dwca"))
  on.exit(setwd(old_wd), add = TRUE)
  
  zip_path <- file.path(td, "dwca_preserve.zip")
  utils::zip(
    zipfile = zip_path,
    files = c("eml.xml", "meta.xml", "occurrence.txt")
  )
  
  file_url <- paste0("file://", normalizePath(zip_path, winslash = "/"))
  
  df <- data.frame(
    recurso_fk = 99L,
    url_ipt = "https://ipt.example.org/resource?r=abc",
    dwca_url = file_url,
    otra_col = "valor",
    stringsAsFactors = FALSE
  )
  
  out <- extract_dwca_metadata(df, progress = FALSE)
  
  testthat::expect_true(all(c("recurso_fk", "url_ipt", "dwca_url", "otra_col") %in% names(out)))
  testthat::expect_equal(out$recurso_fk, 99L)
  testthat::expect_equal(out$otra_col, "valor")
})