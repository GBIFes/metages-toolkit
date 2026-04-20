# Conteo de registros GBIF agregados por nivel taxonomico

Genera una tabla con el numero de registros publicados en GBIF por
Espanha, agregados segun el campo indicado en `facet`.

## Usage

``` r
conteo_registros_por_taxon(
  taxonKey = NULL,
  facet = "phylumKey",
  basisOfRecord = c("PRESERVED_SPECIMEN", "MATERIAL_SAMPLE", "FOSSIL_SPECIMEN")
)
```

## Arguments

- taxonKey:

  Clave taxonomica base.

- facet:

  Campo de agregacion indexado.

- basisOfRecord:

  Vector de tipos de registro a incluir.

## Value

Un tibble con dos columnas:

- Filo:

  Nombre del taxon agregado.

- N registros:

  Numero de registros formateado con separador de miles.

## Details

Incluye una fila adicional denominada TOTAL con la suma global de
registros.

Valores habituales para `taxonKey`:

- `1` = Animalia

- `6` = Plantae

- `5` = Fungi

Valores habituales para `facet` (campos indexados en el endpoint
`/occurrence/count`):

- `"phylumKey"`

- `"classKey"`

- `"orderKey"`

- `"familyKey"`

- `"genusKey"`

- `"speciesKey"`

- `"kingdomKey"`

Ejemplos de `basisOfRecord`:

Especimenes:

    c("PRESERVED_SPECIMEN",
      "MATERIAL_SAMPLE",
      "FOSSIL_SPECIMEN")

Observaciones:

    c("OBSERVATION",
      "HUMAN_OBSERVATION",
      "MACHINE_OBSERVATION")

## Examples

``` r
# Conteo por filo para animales
conteo_registros_por_taxon()
#> # A tibble: 71 × 2
#>    Filo           `Nº registros`
#>    <chr>          <chr>         
#>  1 Tracheophyta   3.136.429     
#>  2 Arthropoda     936.644       
#>  3 Chordata       529.373       
#>  4 Ascomycota     230.347       
#>  5 Basidiomycota  157.322       
#>  6 Mollusca       132.115       
#>  7 Bryophyta      119.498       
#>  8 Ochrophyta     59.232        
#>  9 Rhodophyta     42.740        
#> 10 Proteobacteria 32.229        
#> # ℹ 61 more rows

# Conteo por clase para plantas
conteo_registros_por_taxon(
  taxonKey = 6,
  facet = "classKey"
)
#> # A tibble: 35 × 2
#>    Clase             `Nº registros`
#>    <chr>             <chr>         
#>  1 Magnoliopsida     2.469.579     
#>  2 Liliopsida        516.575       
#>  3 Polypodiopsida    112.730       
#>  4 Bryopsida         106.826       
#>  5 Florideophyceae   41.844        
#>  6 Pinopsida         25.911        
#>  7 Jungermanniopsida 15.828        
#>  8 Lycopodiopsida    8.232         
#>  9 Ulvophyceae       7.498         
#> 10 Sphagnopsida      6.339         
#> # ℹ 25 more rows

# Solo observaciones humanas
conteo_registros_por_taxon(
  basisOfRecord = c("HUMAN_OBSERVATION")
)
#> # A tibble: 100 × 2
#>    Filo             `Nº registros`
#>    <chr>            <chr>         
#>  1 Chordata         48.420.632    
#>  2 Tracheophyta     15.041.835    
#>  3 Arthropoda       1.399.571     
#>  4 Actinobacteriota 146.335       
#>  5 Mollusca         77.078        
#>  6 Basidiomycota    76.350        
#>  7 Ascomycota       70.081        
#>  8 Proteobacteria   68.995        
#>  9 Acidobacteriota  57.547        
#> 10 Mycetozoa        53.926        
#> # ℹ 90 more rows
```
