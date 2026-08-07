crear_dwca_prueba <- function(
    td,
    row_type,
    location,
    lines,
    header_lines = 1L,
    node_name = "core"
) {
  dwca_dir <- file.path(td, "dwca")
  data_path <- file.path(dwca_dir, location)
  dir.create(dirname(data_path), recursive = TRUE, showWarnings = FALSE)

  meta_text <- paste0(
    '<archive xmlns="http://rs.tdwg.org/dwc/text/">',
    '<', node_name, ' rowType="', row_type,
    '" ignoreHeaderLines="', header_lines, '">',
    '<files><location>', location, '</location></files>',
    '</', node_name, '>',
    '</archive>'
  )
  writeLines(meta_text, file.path(dwca_dir, "meta.xml"), useBytes = TRUE)

  # Escribir sin salto final para comprobar que la ultima fila tambien cuenta.
  writeBin(
    charToRaw(paste(lines, collapse = "\n")),
    data_path
  )

  old_wd <- getwd()
  setwd(dwca_dir)
  on.exit(setwd(old_wd), add = TRUE)

  zip_path <- file.path(td, "test_dwca.zip")
  utils::zip(zip_path, files = c("meta.xml", location))
  zip_path
}


testthat::test_that("extract_gbif_metadata() exige dwca_url", {
  testthat::expect_error(
    extract_gbif_metadata(data.frame(x = 1), progress = FALSE),
    "La columna 'dwca_url' no existe en `df`."
  )
})

testthat::test_that("extract_gbif_metadata() conserva el contrato para inputs vacios", {
  input <- data.frame(id = 1:3, dwca_url = c(NA, "", "  "))
  out <- extract_gbif_metadata(input, progress = FALSE)

  testthat::expect_equal(nrow(out), 3L)
  testthat::expect_true(all(c(
    "id", "dwca_url", "eml_title", "eml_version", "eml_pub_date",
    "eml_occurrences", "eml_status", "eml_error_message"
  ) %in% names(out)))
  testthat::expect_true(all(is.na(out$eml_status)))
})

testthat::test_that("extract_gbif_metadata() acepta UUID y URL de dataset", {
  key <- "837381f4-f762-11e1-a439-00145eb45e9a"
  calls <- character()
  xml_calls <- character()

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      calls <<- c(calls, path)
      if (identical(path, paste0("/dataset/", key))) {
        return(list(
          title = "Mi dataset",
          version = "2.3",
          pubDate = "2024-01-15T00:00:00.000+00:00"
        ))
      }
      if (identical(path, "/occurrence/search")) {
        return(list(count = 123))
      }
      stop("Peticion inesperada")
    },
    .gbif_api_get_xml = function(path) {
      xml_calls <<- c(xml_calls, path)
      stop("El EML no deberia solicitarse")
    },
    .package = "metagesToolkit"
  )

  input <- data.frame(
    id = 1:2,
    dwca_url = c(key, paste0("https://www.gbif.org/dataset/", key))
  )
  out <- extract_gbif_metadata(input, progress = FALSE)

  testthat::expect_equal(out$eml_title, c("Mi dataset", "Mi dataset"))
  testthat::expect_equal(out$eml_version, c("V2.3", "V2.3"))
  testthat::expect_equal(out$eml_pub_date, c("2024-01-15", "2024-01-15"))
  testthat::expect_equal(out$eml_occurrences, c(123L, 123L))
  testthat::expect_true(all(out$eml_status == "ok"))
  testthat::expect_equal(sum(calls == paste0("/dataset/", key)), 2L)
  testthat::expect_length(xml_calls, 0L)
})

testthat::test_that("extract_gbif_metadata() resuelve una URL DwC-A en GBIF", {
  key <- "837381f4-f762-11e1-a439-00145eb45e9a"
  dwca <- "https://ipt.gbif.es/archive.do?r=emma"

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (identical(path, "/dataset/search")) {
        return(list(results = list(list(key = key))))
      }
      if (identical(path, paste0("/dataset/", key, "/metadata"))) {
        return(list(
          list(key = 901L, type = "DC"),
          list(key = 902L, type = "EML")
        ))
      }
      if (identical(path, paste0("/dataset/", key))) {
        return(list(
          title = "Herbario EMMA",
          pubDate = "2025-03-20",
          endpoints = list(list(type = "DWC_ARCHIVE", url = dwca))
        ))
      }
      if (identical(path, "/occurrence/search")) {
        return(list(count = 19486))
      }
      stop("Peticion inesperada")
    },
    .gbif_api_get_xml = function(path) {
      testthat::expect_identical(path, "/dataset/metadata/902/document")
      xml2::read_xml('<eml packageId="abcV10.2.1"><dataset/></eml>')
    },
    .package = "metagesToolkit"
  )

  out <- extract_gbif_metadata(
    data.frame(recurso_fk = 7L, dwca_url = dwca),
    progress = FALSE
  )

  testthat::expect_equal(out$recurso_fk, 7L)
  testthat::expect_equal(out$eml_title, "Herbario EMMA")
  testthat::expect_equal(out$eml_version, "V10.2.1")
  testthat::expect_equal(out$eml_pub_date, "2025-03-20")
  testthat::expect_equal(out$eml_occurrences, 19486L)
  testthat::expect_equal(out$eml_status, "ok")
})

testthat::test_that("extract_gbif_metadata() deja version NA sin packageId valido", {
  keys <- c(
    "11111111-1111-1111-1111-111111111111",
    "22222222-2222-2222-2222-222222222222"
  )

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (identical(path, "/occurrence/search")) {
        return(list(count = 0))
      }
      if (grepl("/metadata$", path)) {
        if (grepl(keys[1], path, fixed = TRUE)) {
          return(list(list(key = 101L, type = "EML")))
        }
        return(list(list(key = 102L, type = "EML")))
      }
      list(title = "Dataset", pubDate = "2025-01-01")
    },
    .gbif_api_get_xml = function(path) {
      if (identical(path, "/dataset/metadata/101/document")) {
        return(xml2::read_xml("<eml><dataset/></eml>"))
      }
      xml2::read_xml('<eml packageId="dataset_2025"><dataset/></eml>')
    },
    .package = "metagesToolkit"
  )

  out <- extract_gbif_metadata(
    data.frame(dwca_url = keys),
    progress = FALSE
  )

  testthat::expect_true(all(is.na(out$eml_version)))
  testthat::expect_true(all(out$eml_status == "ok"))
  testthat::expect_true(all(is.na(out$eml_error_message)))
})

testthat::test_that("extract_gbif_metadata() registra errores del documento EML", {
  key <- "33333333-3333-3333-3333-333333333333"

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (grepl("/metadata$", path)) {
        return(list(list(key = 303L, type = "EML")))
      }
      list(title = "Dataset", pubDate = "2025-01-01", count = 1)
    },
    .gbif_api_get_xml = function(path) {
      testthat::expect_identical(path, "/dataset/metadata/303/document")
      stop("Documento EML invalido")
    },
    .package = "metagesToolkit"
  )

  out <- extract_gbif_metadata(
    data.frame(dwca_url = key),
    progress = FALSE
  )

  testthat::expect_equal(out$eml_status, "error")
  testthat::expect_match(out$eml_error_message, "Documento EML invalido")
  testthat::expect_true(is.na(out$eml_version))
})

testthat::test_that("tipo 225 con cero en GBIF cuenta el rowType Taxon", {
  td <- withr::local_tempdir()
  zip_path <- crear_dwca_prueba(
    td = td,
    row_type = "http://rs.tdwg.org/dwc/terms/Taxon",
    location = "nested/species_core.tsv",
    lines = c("id\tname", "1\tTaxon A", "2\tTaxon B"),
    header_lines = 1L
  )
  endpoint <- "https://example.org/checklist.zip"

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (identical(path, "/occurrence/search")) {
        return(list(count = 0))
      }
      list(
        title = "Checklist",
        version = "1.0",
        pubDate = "2026-01-01",
        endpoints = list(list(type = "DWC_ARCHIVE", url = endpoint))
      )
    },
    .package = "metagesToolkit"
  )
  testthat::local_mocked_bindings(
    download.file = function(url, destfile, mode = "wb", quiet = TRUE, ...) {
      testthat::expect_identical(url, endpoint)
      file.copy(zip_path, destfile, overwrite = TRUE)
      invisible(0)
    },
    .package = "utils"
  )

  out <- extract_gbif_metadata(
    data.frame(
      dwca_url = "11111111-1111-1111-1111-111111111111",
      tipo_recurso_id = 225L
    ),
    progress = FALSE
  )

  testthat::expect_equal(out$eml_occurrences, 2L)
  testthat::expect_equal(out$eml_status, "ok")
})

testthat::test_that("tipos 223 y 224 con cero cuentan el rowType Occurrence", {
  td <- withr::local_tempdir()
  zip_path <- crear_dwca_prueba(
    td = td,
    row_type = "http://rs.tdwg.org/dwc/terms/Occurrence",
    location = "data/records_without_expected_name.txt",
    lines = c("comentario", "id", "1", "2", "3"),
    header_lines = 2L,
    node_name = "extension"
  )
  endpoint <- "https://example.org/occurrences.zip"
  downloads <- 0L

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (identical(path, "/occurrence/search")) {
        return(list(count = 0))
      }
      list(
        title = "Occurrences",
        version = "2.0",
        pubDate = "2026-01-01",
        endpoints = list(list(type = "DWC_ARCHIVE", url = endpoint))
      )
    },
    .package = "metagesToolkit"
  )
  testthat::local_mocked_bindings(
    download.file = function(url, destfile, mode = "wb", quiet = TRUE, ...) {
      downloads <<- downloads + 1L
      file.copy(zip_path, destfile, overwrite = TRUE)
      invisible(0)
    },
    .package = "utils"
  )

  out <- extract_gbif_metadata(
    data.frame(
      dwca_url = rep("22222222-2222-2222-2222-222222222222", 2L),
      tipo_recurso_id = c(223L, 224L)
    ),
    progress = FALSE
  )

  testthat::expect_equal(out$eml_occurrences, c(3L, 3L))
  testthat::expect_true(all(out$eml_status == "ok"))
  testthat::expect_equal(downloads, 2L)
})

testthat::test_that("conteos positivos y tipos sin fallback no descargan DwC-A", {
  counts <- c(12, 0, 0)
  call <- 0L

  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (identical(path, "/occurrence/search")) {
        call <<- call + 1L
        return(list(count = counts[call]))
      }
      list(
        title = "Dataset",
        version = "1.0",
        pubDate = "2026-01-01",
        endpoints = list()
      )
    },
    .package = "metagesToolkit"
  )
  testthat::local_mocked_bindings(
    download.file = function(...) stop("No debe descargarse el DwC-A"),
    .package = "utils"
  )

  out <- extract_gbif_metadata(
    data.frame(
      dwca_url = c(
        "33333333-3333-3333-3333-333333333333",
        "44444444-4444-4444-4444-444444444444",
        "55555555-5555-5555-5555-555555555555"
      ),
      tipo_recurso_id = c(225L, 226L, 999L)
    ),
    progress = FALSE
  )

  testthat::expect_equal(out$eml_occurrences, c(12L, 0L, 0L))
  testthat::expect_true(all(out$eml_status == "ok"))
})

testthat::test_that("un fallback imposible devuelve error y occurrences NA", {
  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      if (identical(path, "/occurrence/search")) {
        return(list(count = 0))
      }
      list(
        title = "Checklist",
        version = "1.0",
        pubDate = "2026-01-01",
        endpoints = list()
      )
    },
    .package = "metagesToolkit"
  )

  out <- extract_gbif_metadata(
    data.frame(
      dwca_url = "66666666-6666-6666-6666-666666666666",
      tipo_recurso_id = 225L
    ),
    progress = FALSE
  )

  testthat::expect_true(is.na(out$eml_occurrences))
  testthat::expect_equal(out$eml_status, "error")
  testthat::expect_match(out$eml_error_message, "DWC_ARCHIVE")
})

testthat::test_that("extract_gbif_metadata() registra errores por fila", {
  testthat::local_mocked_bindings(
    .gbif_api_get_json = function(path, query = list()) {
      stop("GBIF no disponible")
    },
    .package = "metagesToolkit"
  )

  out <- extract_gbif_metadata(
    data.frame(dwca_url = "11111111-1111-1111-1111-111111111111"),
    progress = FALSE
  )

  testthat::expect_equal(out$eml_status, "error")
  testthat::expect_match(out$eml_error_message, "GBIF no disponible")
  testthat::expect_true(is.na(out$eml_title))
})
