# Insertar una tabla en un documento Word

Inserta una flextable en un documento Word ya cargado, posicionandola en
el encabezado indicado y gestionando el cambio de secciones entre
orientacion vertical y horizontal.

## Usage

``` r
insertar_tabla_en_doc(doc, keyword, ft)
```

## Arguments

- doc:

  Objeto `rdocx` de officer.

- keyword:

  Texto exacto del encabezado donde se insertara la tabla.

- ft:

  Objeto `flextable` a insertar.

## Value

El objeto `rdocx` modificado.
