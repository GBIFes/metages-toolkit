# Conectar con la base de datos METAGES

Establece una conexión con la base de datos METAGES mediante un túnel
SSH y una conexión ODBC.

## Usage

``` r
conectar_metages()
```

## Value

Una lista con dos elementos:

- con:

  Conexión DBI a la base de datos.

- tunnel:

  Objeto del túnel SSH.

## Details

La función depende de variables de entorno previamente configuradas (por
ejemplo, host, claves SSH y credenciales de base de datos).

La conexión se realiza en dos pasos:

1.  Apertura de un túnel SSH.

2.  Conexión a la base de datos vía DBI/ODBC.
