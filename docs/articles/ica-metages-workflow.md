# Workflow ICA de MetaGES

El workflow consulta MetaGES con
[`conectar_metages()`](https://gbifes.github.io/metages-toolkit/reference/conectar_metages.md),
descarga el Darwin Core Archive actual del IPT y llama al calculador
Python original. No crea tablas.

> **Por defecto solo calcula y muestra resultados.** Para guardarlos hay
> que indicar `write = TRUE`. Los ICAs existentes no se sobrescriben.

## Seleccion de recursos

### URLs admitidas

`url_ipt` admite paginas de recurso y endpoints HTTP(S) directos que
entreguen un DwC-A. Si el dominio tiene una etiqueta `ipt` o la ruta
contiene un segmento `ipt`, solo se convierte el ultimo componente de la
ruta si es exactamente `resource` o `resource.do`, a `archive` o
`archive.do`. Se conservan las barras finales, todos los parametros y el
fragmento. Los archivos como `my-resource.zip` y los directorios
intermedios quedan intactos. Las demas URLs se conservan, sin exigir
extension `.zip` ni parametro `r`. Una respuesta que no sea un DwC-A
valido se registra como error de calculo con las reglas habituales del
workflow.

### Ultima provision publica

Solo considera recursos con `private = 0` y su ultima provision,
ordenada por `provision_fecha` y, en caso de empate, `provision_id`. Las
fechas NULL quedan antes que las conocidas. Si todas son NULL, gana el
mayor ID.

## 1. Preparar el entorno

### Requisitos

**No es necesario crear el venv, activarlo ni instalar el plugin
manualmente.** El sistema debe disponer de:

- Python 3.10 o posterior, con los modulos `venv` y `pip`.
- Git y acceso a Internet.
- Permisos de escritura en el directorio del venv.
- Las variables SSH y ODBC de
  [`conectar_metages()`](https://gbifes.github.io/metages-toolkit/reference/conectar_metages.md)
  para el entorno seleccionado.

El workflow no instala estos programas del sistema.

### Venv y dependencias

`python_executable` o `METAGES_ICA_PYTHON` pueden identificar un Python
de base o el Python de un venv existente. Si se proporciona un Python de
base, el workflow crea un venv persistente en
`$XDG_CACHE_HOME/metagesToolkit/ica-venv` o, si esa variable no esta
definida, en `~/.cache/metagesToolkit/ica-venv`. `METAGES_ICA_VENV`
permite cambiar ese directorio. Si el venv ya existe se reutiliza; si se
proporciona directamente el Python de un venv, se utiliza ese entorno.
No se modifican los paquetes del Python de base.

El workflow instala las dependencias de calculo que falten en el venv:
`python-dwca-reader`, `geopandas`, `numpy`, `pandas`, `pycountry`,
`requests` y `shapely`. Las que ya estan disponibles se conservan.

### Actualizacion del plugin

Al iniciar cada ejecucion, antes de conectar a MetaGES, consulta `main`
con Git y compara su commit con la instalacion local. Si falta el plugin
o no coincide, lo instala con el mismo ejecutable Python, usando
`--force-reinstall --no-deps` para actualizar aunque no cambie su numero
de version. **Si el commit coincide, no reinstala el plugin.**

Requiere acceso a GitHub y permisos de escritura en el directorio del
venv. Si no puede consultar o instalar la ultima revision, se detiene
sin conectar a MetaGES. Esta preparacion tiene un limite de una hora y
se ejecuta una sola vez por llamada al workflow, no por provision. Todos
los calculos posteriores usan el Python del entorno preparado. No se
instala el servidor FAIR EVA.

### Windows y WSL

La implementacion actual importa `fcntl` para bloquear las
actualizaciones del catalogo: Windows nativo no es compatible con ese
modulo. En Windows, el workflow mantiene R y RStudio en Windows y
ejecuta automaticamente solo Python dentro de WSL. SSH, ODBC y la
conexion a MetaGES siguen utilizando la instalacion de R de Windows. No
se necesita instalar R ni el driver ODBC dentro de WSL.

WSL debe tener una distribucion Linux con Python 3.10 o posterior,
`venv`, `pip` y Git. El workflow no instala WSL ni programas del
sistema. Por defecto usa la distribucion predeterminada de WSL;
`METAGES_ICA_WSL_DISTRO` permite elegir otra, por ejemplo
`Ubuntu-22.04`. `python_executable = "python3"` identifica Python dentro
de esa distribucion. El valor predeterminado `"python"` se interpreta
como `"python3"` en WSL; no se utilizan los accesos directos de
Microsoft Store ni los ejecutables Python de Windows.

> **Si falta `ensurepip`:** instalar una vez el componente del sistema
> desde la terminal de Ubuntu con `sudo apt install python3-venv`.

La preparacion automatica de las dependencias Python se reanuda al
repetir la llamada desde R.

El workflow traduce la ruta del runner mediante `wslpath` y envia el
JSON por la entrada estandar. Transmite tambien `METAGES_ICA_VENV` y
`METAGES_ICA_CATALOGUE_DIR`, traduciendo sus rutas de Windows cuando
corresponda. Se recomienda guardar el venv y el catalogo en rutas de
Linux, por ejemplo `/home/usuario/.cache/metagesToolkit/ica-venv`. Una
vez preparado el entorno, reutiliza su ejecutable Linux para todas las
provisiones. En Linux la llamada a Python sigue siendo directa. El
paquete Python incorpora los mapas necesarios. Se carga `quality.py` con
contexto de paquete para resolver `catalogue.py`, por lo que no hace
falta instalar el servidor FAIR EVA. El workflow comprueba las
dependencias antes de conectar a MetaGES. Cada calculo tiene un limite
de una hora.

### Variables de configuracion

| Variable | Para que sirve |
|:---|:---|
| `METAGES_ICA_PYTHON` | Python de base o de un venv existente; en Windows, el de WSL. |
| `METAGES_ICA_WSL_DISTRO` | Elegir la distribucion WSL, por ejemplo `Ubuntu-22.04`. |
| `METAGES_ICA_VENV` | Cambiar el directorio del venv gestionado por el workflow. |
| `METAGES_ICA_CATALOGUE_DIR` | Elegir el directorio de cache del catalogo. |

## 2. Ejecutar el workflow

### Probar provisiones concretas

``` r

library(metagesToolkit)

# Calculo real, sin ninguna escritura, incluidos los errores.
resultado <- ica_metages_workflow(
  entorno = "test",
  provision_ids = c(123, 456),
  python_executable = "python3"
)

resultado
```

> **Los IDs 123 y 456 son ilustrativos.** Sustituirlos por IDs de
> provisiones del entorno seleccionado, no por IDs de recursos.

### Guardar resultados en MetaGES

``` r

# Todas las ultimas provisiones publicas con los cinco campos NULL.
resultado <- ica_metages_workflow(
  entorno = "test",
  write = TRUE,
  python_executable = "python3"
)
```

### Exportar una copia local

``` r

# Guardar el resultado local para inspeccion.
jsonlite::write_json(
  resultado,
  "ica-results.json",
  dataframe = "rows",
  pretty = TRUE,
  na = "null",
  digits = NA
)
```

## 3. Interpretar los resultados

### Estados del procesamiento

| `status` | Significado |
|:---|:---|
| `preview` | Calculo correcto, sin guardar. |
| `inspection` | Calculo para inspeccion; conserva los valores ya guardados. |
| `updated` | Resultado guardado con `write = TRUE`. |
| `changed` | La provision cambio durante el calculo; no se guardo el resultado. |
| `omitted` | Provision no elegible; consultar el motivo en `detail`. |
| `error` | Fallo de descarga, validacion o calculo; consultar `detail`. |

La ejecucion automatica omite provisiones con cualquier campo ya
relleno. Una lista manual permite recalcular la ultima provision con
valores existentes, pero su estado sera `inspection` y nunca se
escribira en esa provision. Los IDs historicos, privados o inexistentes
reciben `omitted`. `provision_ids` identifica filas de
`metages_provision_recurso`, no IDs de `metages_recurso`. Los IDs 123 y
456 del ejemplo son ilustrativos: sustituirlos por provisiones reales
del entorno seleccionado. Que un recurso exista en el IPT o tenga un ICA
anterior no garantiza que una provision concreta siga siendo la ultima
ni que este marcada como publica en MetaGES. `detail` distingue una
provision historica, un recurso privado, privacidad no definida y una
provision inexistente o sin recurso asociado. Los valores nulos de las
puntuaciones en una fila omitida no representan los valores guardados:
no se ha recalculado esa provision ni se han borrado sus datos.

### Componentes y precision

Los componentes mantienen las unidades originales: `Taxonomic` en
`Icat`, `Geographic` en `Icag` y `Temporal` en `Icad`. Tanto `ICA` como
estos tres componentes se truncan hacia cero a cuatro decimales. Si esos
cuatro decimales son cero, se conserva hasta el primero distinto de
cero: `12.345678` pasa a `12.3456`, `0.000012345` a `0.00001` y
`12.0000567` a `12.00005`. El cero exacto permanece cero. Esta regla se
aplica tanto al resultado como a la escritura; no modifica registros
existentes.

| Valor original | Valor truncado |
|---------------:|---------------:|
|    `12.345678` |      `12.3456` |
|  `0.000012345` |      `0.00001` |
|   `12.0000567` |     `12.00005` |
|   `-0.0000567` |     `-0.00005` |
|            `0` |            `0` |

`ICA` se obtiene del resultado original del plugin y despues se trunca;
no se recalcula sumando los componentes ya truncados. Las columnas de
MetaGES deben admitir la precision adicional; comprobar sus tipos antes
de habilitar escritura. El calculador puede producir valores negativos
por penalizaciones. `fecha_validacion` es la fecha del calculo: la
funcion original no devuelve una fecha.

## 4. Escritura y tratamiento de errores

### Proteccion de los datos

Con `write = TRUE`, los resultados completos se guardan juntos,
revalidando privacidad, ultima provision, URL y campos vacios dentro de
una transaccion. Si cambiaron, el estado sera `changed`.

### Errores y auditoria

Un fallo de calculo deja `error` y agrega una nota fechada `[ICA]` a
`provision_obs` en las provisiones elegibles, preservando las
observaciones y evitando duplicar el mismo mensaje. Un fallo de conexion
o escritura detiene la ejecucion. Las notas no se borran tras un
reintento correcto. Cada escritura efectiva, de resultados o de una
nueva nota de error, actualiza `updated_when` con la fecha y hora del
servidor y `updated_who` con `ica_metages_workflow`. Las ejecuciones sin
escritura, las provisiones omitidas y los errores ya registrados no
modifican esos campos.

El plugin actual propaga los errores de dependencias, catalogo y
validacion. El adaptador tambien rechaza resultados incompletos o no
finitos.

> **Primera ejecucion:** el plugin descarga automaticamente Catalogue of
> Life y conserva una cache local para reutilizarla. Esa primera
> descarga requiere conexion a Internet y espacio en disco.
> `METAGES_ICA_CATALOGUE_DIR` permite elegir otro directorio de cache;
> no es necesario descargar el catalogo manualmente.
