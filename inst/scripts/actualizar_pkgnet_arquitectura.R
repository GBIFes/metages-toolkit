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
stopifnot(requireNamespace("devtools", quietly = TRUE))


# ------------------------------------------------------------
# OPCIÓN A — USAR REPOSITORIO LOCAL (desarrollo)
# ------------------------------------------------------------

src <- "."  # repo local
devtools::install(".", upgrade = "never", dependencies = FALSE, quiet = TRUE)


# ------------------------------------------------------------
# OPCIÓN B — CLONAR REPOSITORIO OFICIAL (CI / publicación)
# ------------------------------------------------------------

# repo_url <- "https://github.com/GBIFes/metages-toolkit.git"
# src <- tempfile("metagesToolkit-official-")
# git2r::clone(repo_url, src)
# devtools::install(src, upgrade = "never", dependencies = FALSE, quiet = TRUE)


# ------------------------------------------------------------
# Metadatos desde DESCRIPTION
# ------------------------------------------------------------

dcf <- read.dcf(file.path(src, "DESCRIPTION"))

pkg_name <- dcf[1, "Package"]
version  <- dcf[1, "Version"]

message("Generando reporte pkgnet para ", pkg_name,
        " (versión ", version, ")")


# ------------------------------------------------------------
# Salida pkgdown
# ------------------------------------------------------------

out_dir <- file.path("pkgdown", "assets")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "pkgnet-report.html")


# ------------------------------------------------------------
# Generar reporte pkgnet
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
