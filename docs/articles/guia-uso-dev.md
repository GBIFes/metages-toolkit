# Guia de uso de metages-toolkit — DESARROLLADORES

Esta vignette documenta **cómo usar y mantener el repositorio
`metages-toolkit`** como **DESARROLLADOR**. Está pensada como documento
vivo y referencia operativa.

------------------------------------------------------------------------

## Alcance

> Glosario de términos
>
> - **MetaGES** — Nombre de la base de datos del Registro de Colecciones
>   de GBIF.ES
>
> - **metages-toolkit** — Nombre del repositorio GitHub que gestiona los
>   datos de MetaGES y crea la [GitHub
>   Page](https://gbifes.github.io/metages-toolkit/) del repo (alberga
>   metagesToolkit)
>
> - **metagesToolkit** — Nombre del paquete R de uso interno para **leer
>   y analizar** el Registro de Colecciones de GBIF.ES (MetaGES).

`metages-toolkit` integra:

- extracción de datos desde MetaGES,
- generación de mapas y gráficos,
- construcción de informes (Quarto → Word),
- publicación de documentación vía **pkgdown / GitHub Pages**.
- mantenimiento de scripts `SQL` de la base de datos MetaGES

------------------------------------------------------------------------

## Estructura del repositorio

- `R/` — funciones del paquete R `metagesToolkit` (exportadas y
  auxiliares)

- `man/` — documentación de las funciones de R (generada por `roxygen`)

- `tests/` — tests unitarios de las funciones de R (usa `testthat`)

- `inst/`

  - `reports/` — recursos del informe `Quarto`

    - `informe.qmd` — documento orquestador del informe

    - `assets/` (logos, imágenes externas y generadas)

    - `data/`

      - `mapas/` — datasets `.rds` ya filtradas por casos de uso
        utilizados en mapas y graficos
      - `vistas_sql/` — datasets `.rds` procedentes de vistas SQL de
        MetaGES

  - `scripts/`

    - scripts de actualización de archivos internos (`pkgnet` output,
      mapas-graficos-y-datasets de `metagesToolkit`, documentacion SQL
      de vistas y scripts de `MetaGES` y archivo `.Renviron`)
    - scripts en desarrollo que aun no forman parte de metagesToolkit
    - scripts de gestion de MetaGES

- `sql/` — scripts SQL de MetaGES documentados/exportados

- `docs/` — salida de pkgdown (GitHub Pages)

- `_pkgdown.yml` — configuración del website

------------------------------------------------------------------------

## Configuracion de `.Renviron` para acceder a MetaGES

El acceso a MetaGES esta protegido por credenciales. Configurar estas
credenciales en R es fundamental para usar el paquete tanto como
`DESARROLLADOR` como como `USUARIO`

### Flujo recomendado

``` r
# 1. Abrir .Renviron
usethis::edit_r_environ()

# 2. Modificar el documento que aparece, añadiendo las variables de entorno asi:
 nombre-visible-variable-de-entorno1 = "contenido-privado-variable-de-entorno1"
 nombre-visible-variable-de-entorno2 = "contenido-privado-variable-de-entorno2"
 ...
    # 2.1 Las variables de entorno necesarias para conectarse a MetaGES son:
    host_prod
    keyfile
    prod_ssh_bridge_R
    Database
    UID
    gbif_wp_pass

# 3. Guardar documento. Correr desde la consola con .Renviron abierto
rstudioapi::documentSave()

# 4. Hacer efectivos los cambios reiniciando la sesion de R
rstudioapi::restartSession()
```

------------------------------------------------------------------------

## Desarrollo local como usuario externo

Cuando se esta actualizando metagesToolkit, combiene testarlo como
usuario antes de publicarlo en GitHub para evitar errores de rutas y
dependencias implícitas del repo, **no confiar solo en
[`devtools::load_all()`](https://devtools.r-lib.org/reference/load_all.html)**.
Esto garantiza que el comportamiento sea el mismo que para un usuario
real.

### Flujo recomendado

``` r
# Correr desde la `root` de metagesToolkit


# Abrir proyecto metagesToolkit (para acceder a funciones de desarrollo)
rstudioapi::openProject("metagesToolkit.Rproj")

# Hacer cambios deseados

# Instalar paquete metagesToolkit en desarrollo local
devtools::install(".", upgrade = "never")

# Reiniciar sesión R
rstudioapi::restartSession()

# Cargar el paquete en desarrollo
library(metagesToolkit)

# Testar funcionalidad añadida

# Volver a instalar version oficial de metagesToolkit
devtools::install_github("GBIFes/metages-toolkit")

# Volver a reiniciar sesión R
rstudioapi::restartSession()
```

------------------------------------------------------------------------

## Actualización de datasets, mapas y gráficos del repo

Muchos de los datasets, mapas y gráficos usados por el paquete **no se
generan en tiempo real** para los usuarios, sino que se actualizan
mediante scripts controlados con antelacion para optimizar performance.

> Este script:
>
> - extrae datos actualizados
>
> - regenera mapas y gráficos
>
> - guarda los resultados como `.rds` y `.png`

### Flujo recomendado

1.  Ejecutar el script de actualización.

``` r
# Correr desde la `root` de metagesToolkit


# Abrir proyecto metagesToolkit (para acceder a funciones de desarrollo)
rstudioapi::openProject("metagesToolkit.Rproj")

# Regenerar recursos internos de metagesToolkit
source("inst/scripts/actualizar_mapas_vignettes.R")
```

2.  Validar manualmente los outputs en:

- `inst/reports/data/mapas/` — para datasets filtradas segun
  [`crear_mapa_simple()`](https://gbifes.github.io/metages-toolkit/reference/crear_mapa_simple.md)
- `inst/reports/data/vistas_sql/` — para datasets provenientes
  directamente de MetaGES mediante `SQL scripts`
- `inst/reports/assets/images/generated/` — para imagenes de mapas y
  graficos generadas mediante diversas funciones de metagesToolkit

------------------------------------------------------------------------

## Actualización de GitHub Pages

La documentación pública del paquete se publica mediante **pkgdown** en
GitHub Pages.

### Flujo recomendado

1.  Hacer cambios funcionales del repo

``` r
# Correr desde la `root` de metagesToolkit. Seguir pasos en este orden especifico.

# Abrir proyecto metagesToolkit (para acceder a funciones de desarrollo)
rstudioapi::openProject("metagesToolkit.Rproj")

# Hacer los cambios deseados en el repo

# Testear los cambios
devtools::test()

# Regenerar documentación del paquete
devtools::document()

# Comprobacion final de cambios
devtools::check()
```

2.  Commit de cambios funcionales

``` bash
git add .
git commit -m "fix(test): Debug en test..."
```

3.  Cambio de version

``` r
# Cambiar version del paquete, se aceptan: "patch", "minor" y "major"
usethis::use_version("patch")
```

4.  Commit del cambio de version

``` bash
git add DESCRIPTION
git commit -m "feat(repo): Publicar version X.Y.Z"
```

5.  Actualizar website localmente

``` r
# Actualizar Analisis estructural de metagesToolkit
source("inst/scripts/actualizar_pkgnet_arquitectura.R")

# Reconstruir el website
pkgdown::clean_site()
pkgdown::build_site()

# Revisar el website
browseURL("docs/index.html")
```

6.  Commit y push del website.

``` bash
git add docs/
git add pkgdown/
git commit -m "feat(repo): Actualizar pkgdown site for vX.Y.Z"
git push
```

------------------------------------------------------------------------

## Actualización de scripts SQL de MetaGES

MetaGES guarda el codigo de las vistas SQL, pero no guarda la
documentacion de dicho codigo. Para mantener un control de versiones del
codigo de estas vistas (y otros scripts de MetaGES — `calitests`), estos
scripts SQL documentados usan Github y viven en la carpeta `sql/` de
metagesToolkit.

### Flujo recomendado

``` r
# Abrir proyecto metagesToolkit (para acceder a funciones de desarrollo)
rstudioapi::openProject("metagesToolkit.Rproj")

# IMPORTANTE: Leer detenidamente la documentacion, ya que depende del ordenador con que se use
file.edit("sql/LEEME")

# Actualizar scripts
source("inst/scripts/actualizar_SQL_scripts.R")

# Revisar que los Scripts SQL de MetaGES coinciden con el contenido de la carpeta sql
```

------------------------------------------------------------------------

## Notas finales

- Este documento describe **el flujo esperado**, no todos los detalles
  de implementación.
- Ante cambios estructurales (rutas, nombres, outputs), este
  `guia-uso-dev.Rmd` debe actualizarse.
- Para entender dependencias internas de metagesToolkit, consultar el
  reporte de **Arquitectura** generado con `pkgnet` incluido en la barra
  de navegacion al inicio del renderizado de `pkgdown` de este
  documento.
