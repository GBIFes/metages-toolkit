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
#>  1 Tracheophyta   3.159.328     
#>  2 Arthropoda     938.258       
#>  3 Chordata       529.524       
#>  4 Ascomycota     231.120       
#>  5 Basidiomycota  158.632       
#>  6 Mollusca       132.115       
#>  7 Bryophyta      119.498       
#>  8 Ochrophyta     59.231        
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
#>  1 Magnoliopsida     2.482.923     
#>  2 Liliopsida        525.704       
#>  3 Polypodiopsida    112.946       
#>  4 Bryopsida         106.826       
#>  5 Florideophyceae   41.844        
#>  6 Pinopsida         26.042        
#>  7 Jungermanniopsida 15.825        
#>  8 Lycopodiopsida    8.286         
#>  9 Ulvophyceae       7.498         
#> 10 Sphagnopsida      6.339         
#> # ℹ 25 more rows

# Solo observaciones humanas
conteo_registros_por_taxon(
  basisOfRecord = c("HUMAN_OBSERVATION")
)
#> # A tibble: 99 × 2
#>    Filo             `Nº registros`
#>    <chr>            <chr>         
#>  1 Chordata         48.551.391    
#>  2 Tracheophyta     15.114.385    
#>  3 Arthropoda       1.428.575     
#>  4 Actinobacteriota 146.335       
#>  5 Mollusca         79.921        
#>  6 Basidiomycota    77.374        
#>  7 Ascomycota       74.379        
#>  8 Proteobacteria   68.997        
#>  9 Acidobacteriota  57.547        
#> 10 Mycetozoa        53.941        
#> # ℹ 89 more rows
```
