# Crear mapa de entidades en el Registro facetado segun publicacion en GBIF

Genera un mapa del país que muestra la localizacion de las entidades
incluidas en el Registro de Colecciones de GBIF.ES. El mapa se facetiza
segun el estado de publicacion en GBIF (`publica_en_gbif`), separando
visualmente las entidades que publican de aquellas que no.

## Usage

``` r
crear_mapa_entidades(tipo_coleccion = NULL)
```

## Arguments

- tipo_coleccion:

  Tipo de entidad a representar. Uno de `"coleccion"`, `"base de datos"`
  o `NULL`. Si es `NULL`, se muestran todas.

## Value

Un objeto `ggplot`.

## Details

Las entidades se representan mediante puntos fijos. Para evitar
ocultamientos completos entre entidades cercanas, se aplica un jitter
espacial muy leve. Los nombres que aparecen en el mapa corresponden a
las regiones, y se situan en el centroide empirico de las entidades de
cada region y panel, manteniendo coherencia cartografica.
