# Guia de uso de metagesToolkit — USUARIOS

Esta vignette documenta **cómo usar y explorar el paquete de R
`metagesToolkit`** como **USUARIO**. Está pensada como documento vivo y
referencia operativa.

------------------------------------------------------------------------

## Configuracion de `.Renviron`

👉 Consulta el artículo [Configuracion de `.Renviron` para acceder a
MetaGES](https://gbifes.github.io/metages-toolkit/articles/guia-uso-dev.html#configuracion-de--renviron-para-acceder-a-metages)

------------------------------------------------------------------------

## Instalacion del paquete

El paquete de R metagesToolkit se instala directamente desde GitHub:

``` r
# install.packages("remotes")
remotes::install_github("GBIFes/metages-toolkit")

# Para desarrollo local del paquete se recomienda utilizar `devtools`, pero no es necesario para su uso normal.
# install.packages("devtools")
# devtools::install_github("GBIFes/metages-toolkit")
```

## Extracción de datos

Existen varias maneras de explorar MetaGES dependiendo de si se mira la
base de datos directamente o si se usan funciones de metagesToolkit.
Para ambas, es necesario tener [acceso a
MetaGES](https://gbifes.github.io/metages-toolkit/articles/guia-uso-dev.html#configuracion-de--renviron-para-acceder-a-metages).

### Mediante funciones de metagesToolkit

> Tener en cuenta que la funcion `extraer_colecciones_mapa.R` filtra
> MetaGES para proveer **registros de calidad**. Por lo tanto no
> proporciona la lista completa de registros de colecciones y bases de
> datos de MetaGES. Para acceder a todos los datos de MetaGES, acceder
> [Mediante llamadas SQL a
> MetaGES](https://gbifes.github.io/metages-toolkit/articles/guia-uso-dev.html#mediante-llamadas-sql-a-metages)

``` r
# Cargar el paquete instalado para poder usarlo
library(metagesToolkit)

# Extrae una lista que llamamos `datos`
datos <- extraer_colecciones_mapa()
#> Aviso:
#> Disconnecting from unused ssh session. Please use ssh_disconnect()

# Visualizar los datos extraidos
View(datos$data)
```

### Mediante llamadas SQL a MetaGES

``` r
# Cargar DBI para conexiones a bases de datos
library(DBI)

# Establecer la conexion
con <- conectar_metages()$con

# Explorar la base de datos MetaGES. Esta lista muestra las tablas y vistas disponibles
dbListTables(con)

# Extraer los datos seleccionados como objeto de R. Admite queries complejos.
df <- dbGetQuery(con, 
                 "SELECT * FROM colecciones_por_disciplina")

# Desconectar de MetaGES
dbDisconnect(con)
```

------------------------------------------------------------------------

## Creación de mapas

La funcion
[`crear_mapa_simple()`](https://gbifes.github.io/metages-toolkit/reference/crear_mapa_simple.md)
permite crear mapas y los datos que los generan usando argumentos que
filtran o facetan los datos. Los argumentos son **opcionales** y se
pueden combinar entre ellos para generar diferentes tipos de mapas.

Permite filtrar por:

- `tipo_coleccion`
- `disciplina`, `subdisciplina`
- `publican`

Permite facetar usando:

- `facet` (cualquier columna del dataset)

``` r
# Funcion con los argumentos disponibles sin usar
crear_mapa_simple(tipo_coleccion,
                   disciplina,
                   subdisciplina,
                   publican,
                   facet)



# Para ver las opciones disponibles para cada argumento de la funcion, se pueden 
# sacar las variables del dataset descargado anteriormente usando `datos <- extraer_colecciones_mapa()`. 
# Las siguientes variables podran ser usadas en cada argumento.


# TIPO_COLECCION
unique(datos$data$tipo_body)
# [1] "coleccion"     "base de datos"

# DISCIPLINA
unique(datos$data$disciplina_def)
# [1] "Microbiológica" "Botánica"       "Mixta"          "Zoológica"  
# [5] "Micológica"     "Paleontológica"

# SUBDISCIPLINA
unique(datos$data$disciplina_subtipo_def)
# [1] NA                            "Plantas"                    
# [3] "Vertebrados"                 "Invertebrados"              
# [5] "Invertebrados y vertebrados" "Algas"                      
# [7] "Hongos"

# PUBLICAN
unique(datos$data$publica_en_gbif)
# [1] 1         0

# FACET
# Todas las variables de los datos descargados pueden ser utilizados como `facet` en teoria, 
# pero de una en una.
# IMPORTANTE: solo deben ser usadas como `facet` las variables categoricas de pocos valores unicos, 
# ya que `facet` dividira el grafico en tantos mapas como valores unicos tenga la variable seleccionada.
names(datos$data)
  # [1] "body_id"                        "institucion_proyecto"          
  # [3] "url_institucion"                "coleccion_base"                
  # [5] "coleccion_url"                  "collection_code"               
  # [7] "number_of_subunits"             "percent_database"              
  # [9] "percent_georref"                "disciplina_def"                
  # [11] "disciplina_subtipo_def"         "town"                          
  # [13] "latitude"                       "longitude"                     
  # [15] "region"                         "tipo_body"                     
  # [17] "publica_en_gbif"                "numberOfRecords"               
  # [19] "fecha_alta_coleccion"           "ultima_actualizacion_coleccion"
  # [21] "ultima_actualizacion_recursos"  "disciplina_id"                 
  # [23] "condiciones_col"                "acceso_ejemplares"             
  # [25] "acceso_informatizado"           "medio_acceso"                  
  # [27] "software_gestion_col"           "longitude_adj"                 
  # [29] "latitude_adj"



# EJEMPLO DE USO 1
# Funcion con filtros en sus argumentos:
mapa1 <- crear_mapa_simple(tipo_coleccion = "coleccion",
                           disciplina = "Botánica",
                           subdisciplina = "Plantas",
                           publican = 1) # 1/TRUE = VERDADERO, 0/FALSE = FALSE
# Visualizar el mapa
mapa1$plot
# Visualizar los datos que han generado el mapa
mapa1$data_map


# EJEMPLO DE USO 2
# Funcion usando filtros y facet:
mapa2 <- crear_mapa_simple(tipo_coleccion = "coleccion",
                           publican = TRUE,
                           facet = "disciplina_def")
mapa2$plot
mapa2$data_map
```

------------------------------------------------------------------------

## Generacion del Informe de Colecciones

El Informe de colecciones de GBIF.ES se genera utilizando un documento
`.qmd` (Quarto) que utiliza las funciones y recursos de metagesToolkit
para producir un documento `.docx` editable con toda la informacion
necesaria para ser validado por un humano.

### Requerimientos

Para optimizar la produccion del informe, se usan recursos ya generados
y guardados con anterioridad en metagesToolkit por lo que el primer paso
sera actualizar estos recursos.

Para actualizarlos, 👉 Consulta el artículo [Actualización de datasets,
mapas y gráficos del
repo](https://gbifes.github.io/metages-toolkit/articles/guia-uso-dev.html#actualizaci%C3%B3n-de-datasets-mapas-y-gr%C3%A1ficos-del-repo)

### Renderizar informe

``` r
# RENDERIZAR INFORME
# Crea una carpeta `informe_output` en el `directorio raiz` con todos los 
# recursos usados para generar el informe.
# El informe se encuentra en `informe_output/reports/informe.docx`
render_informe()


# ADICION DE ANEXOS
# En el mismo directorio donde se encuentra `informe.docx`, esta funcion crea 
# `informe_con tablas_colecciones.docx` que es una version actualizada de `informe.docx`.
# El argumento `keyword` debe referenciar una seccion existente del `informe.docx`
# generado por `render_informe()`
insertar_tabla_colecciones(keyword = "Anexos") 
```

## Acceso a recursos internos de metagesToolkit

Un usuario de metagesToolkit puede acceder a los recursos que contiene
**sin necesidad de estar conectado a la base de datos MetaGES**, usando
el siguiente codigo:

### Acceso a datasets

``` r
# Ruta a los recursos del paquete
ruta_mapas <- system.file("reports", "data", "mapas",
                          package = "metagesToolkit"
                        )

# Listado de recursos disponibles
list.files(ruta_mapas)

# Seleccion de dataset deseada
ruta <- system.file("reports", "data", "mapas",
                    "mapa-colecciones-alg.rds", # Dataset seleccionada
                    package = "metagesToolkit"
                  )

# Visualizar dataset
View(readRDS(ruta)) 
```

------------------------------------------------------------------------

### Acceso a mapas y gráficos

Imágenes disponibles en:

- `inst/reports/assets/images/logos/`
- `inst/reports/assets/images/external/`
- `inst/reports/assets/images/generated/`

``` r
# Ruta a los recursos del paquete
ruta_plots <- system.file("reports", "assets", "images", "generated",
                          package = "metagesToolkit"
                        )

# Listado de recursos disponibles
list.files(ruta_plots)

# Seleccion de dataset deseada
ruta <- system.file("reports", "assets", "images", "generated",
                    "mapa-colecciones-inv.png", # Plot seleccionado
                    package = "metagesToolkit"
                  )

# Visualizar dataset
browseURL(ruta)
```

------------------------------------------------------------------------

## Notas finales

- Este documento describe **el flujo esperado**, no todos los detalles
  posibles de uso.
- Ante cambios estructurales (rutas, nombres, outputs, funciones), este
  `guia-uso-usr.Rmd` debe actualizarse.
