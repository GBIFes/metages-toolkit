# ------------------------------------------------------------
# Generar reporte de arquitectura interna con pkgnet
#
# - Fuente: repositorio oficial (GitHub)
# - Versión: tomada de DESCRIPTION (fuente de verdad)
# - Output: HTML standalone
# - Destino: pkgdown/assets/ (copiado siempre al site)
#
# Este script NO se ejecuta desde vignettes ni pkgdown.
# Se ejecuta manualmente o en CI, antes de build_site().
# ------------------------------------------------------------

# Dependencias (script de mantenimiento)
stopifnot(requireNamespace("pkgnet", quietly = TRUE))
stopifnot(requireNamespace("git2r", quietly = TRUE))

repo_url <- "https://github.com/GBIFes/metages-toolkit.git"

# ------------------------------------------------------------
# 1. Clonar repositorio oficial en entorno limpio
# ------------------------------------------------------------

src <- tempfile("metagesToolkit-official-")
git2r::clone(repo_url, src)

# ------------------------------------------------------------
# 2. Leer metadatos desde DESCRIPTION
# ------------------------------------------------------------

desc_path <- file.path(src, "DESCRIPTION")
dcf <- read.dcf(desc_path)

pkg_name <- dcf[1, "Package"]
version  <- dcf[1, "Version"]

message("Generando reporte pkgnet para ", pkg_name,
        " (versión ", version, ")")

# ------------------------------------------------------------
# 3. Preparar carpeta de salida para pkgdown
# ------------------------------------------------------------

out_dir <- file.path("pkgdown", "assets")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_file <- file.path(out_dir, "pkgnet-report.html")

# ------------------------------------------------------------
# 4. Generar reporte HTML standalone con pkgnet
# ------------------------------------------------------------

pkgnet::CreatePackageReport(
  pkg_name    = pkg_name,
  pkg_path    = src,
  report_path = out_file
)

# ------------------------------------------------------------
# 5. Mensaje final
# ------------------------------------------------------------

message("Reporte pkgnet generado correctamente:")
message(normalizePath(out_file))
