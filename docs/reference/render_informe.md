# Renderiza el informe METAGES

Renderiza el archivo Quarto `informe.qmd` incluido en el paquete
metagesToolkit y genera un informe Word (`.docx`) junto con todos los
archivos auxiliares producidos por Quarto.

## Usage

``` r
render_informe(overwrite = TRUE)
```

## Arguments

- overwrite:

  Si `TRUE`, elimina y vuelve a crear el directorio `informe_output` si
  ya existe en el directorio de trabajo. Si `FALSE` y el directorio
  existe, la funcion lanza un error.

## Value

Crea varias carpetas y archivos de cache, figuras y un documento
(`.docx`).

## Details

El informe se renderiza en un directorio temporal y, una vez finalizado,
todo el contenido generado se copia al directorio de trabajo actual
dentro de la carpeta `informe_output`, preservando la estructura de
subdirectorios.
