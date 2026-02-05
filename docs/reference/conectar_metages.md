# Conectar con la base de datos METAGES

Establece una conexión con la base de datos METAGES mediante un túnel
SSH y una conexión ODBC.

## Usage

``` r
conectar_metages(driver = NULL)
```

## Arguments

- driver:

  Nombre del driver ODBC a utilizar. Por defecto se usa
  `"MySQL ODBC 9.4 Unicode Driver"`, pero puede variar segun el sistema
  operativo y la instalacion local. **Solo se admiten drivers ODBC
  Unicode**. Los drivers ANSI no estan soportados. Para listar los
  drivers disponibles desde R:
  [`odbc::odbcListDrivers()`](https://odbc.r-dbi.org/reference/odbcListDrivers.html).
  En sistemas donde el driver por defecto no funcione, el usuario deberá
  especificar uno alternativo mediante el argumento `driver`.

## Value

Una lista con dos elementos:

- con:

  Conexión DBI a la base de datos.

- tunnel:

  Objeto del túnel SSH.

## Details

La función depende de variables de entorno previamente configuradas (por
ejemplo, host, claves SSH y credenciales de base de datos). Para mas
informacion sobre la configuracion de las variables de entorno, ver
[Documentación técnica de
metagesToolkit](https://gbifes.github.io/metages-toolkit/articles/guia-uso-dev.html#configuracion-de--renviron-para-acceder-a-metages)

La conexión se realiza en dos pasos:

1.  Apertura de un túnel SSH.

2.  Conexión a la base de datos vía DBI y ODBC.

La base de datos MetaGES utiliza codificacion UTF-8 y contiene
caracteres internacionales (acentos, caracteres cientificos, etc.).

Por este motivo, `conectar_metages()` **solo permite el uso de drivers
ODBC Unicode**. Los drivers ODBC ANSI no soportan correctamente UTF-8 y
pueden provocar errores silenciosos o corrupcion de texto.

Si no se especifica un driver, la función utiliza el driver Unicode por
defecto. Si dicho driver no está instalado en el sistema, la conexión
fallará.

Para instalar un driver ODBC Unicode para MySQL, consulte la página
oficial: <https://dev.mysql.com/downloads/connector/odbc/>
