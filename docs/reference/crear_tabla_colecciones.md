# Crear tabla de colecciones filtrada

Construye una tabla de colecciones y bases de datos a partir de los
datos devueltos por
[`extraer_colecciones_mapa()`](https://gbifes.github.io/metages-toolkit/reference/extraer_colecciones_mapa.md),
aplicando filtros opcionales por disciplina y/o subdisciplina. La tabla
resultante esta preparada para su uso posterior en una `flextable`.

## Usage

``` r
crear_tabla_colecciones(filtro = list())
```

## Arguments

- filtro:

  Lista con criterios de filtrado. Puede contener los elementos
  `disciplina` y/o `subdisciplina`, cuyos valores deben coincidir
  exactamente con los existentes en los datos.

## Value

Un `data.frame` con las columnas transformadas, formateadas y listas
para su visualizacion en una tabla.

## Details

Esta funcion no realiza ninguna operacion de entrada/salida ni modifica
documentos Word. Su unica responsabilidad es la preparacion de los
datos.
