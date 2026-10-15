# Calcular ICA para las ultimas provisiones publicas de MetaGES

Usa conectar_metages() y el calculador Python original de GBIF.

## Usage

``` r
ica_metages_workflow(
  entorno = c("test", "prod"),
  provision_ids = NULL,
  write = FALSE,
  python_executable = Sys.getenv("METAGES_ICA_PYTHON", "python")
)
```

## Arguments

- entorno:

  Entorno de conexion: test (por defecto) o prod.

- provision_ids:

  IDs opcionales. Las provisiones con valores existentes se calculan
  para inspeccion, sin escribir.

- write:

  Escribir resultados y errores en MetaGES. Por defecto FALSE.

- python_executable:

  Python de base o de un venv existente. El workflow prepara
  automaticamente el entorno y las dependencias de calculo. En Windows
  identifica el Python de Linux que se ejecuta mediante WSL.

## Value

Data frame de resultados, estados y errores por provision.
