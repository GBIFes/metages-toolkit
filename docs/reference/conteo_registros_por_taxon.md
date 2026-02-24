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
#>  1 Tracheophyta   3.133.757     
#>  2 Arthropoda     903.506       
#>  3 Chordata       501.660       
#>  4 Ascomycota     225.366       
#>  5 Basidiomycota  157.217       
#>  6 Mollusca       125.216       
#>  7 Bryophyta      118.810       
#>  8 Rhodophyta     42.463        
#>  9 Proteobacteria 32.229        
#> 10 Ochrophyta     29.629        
#> # ℹ 61 more rows

# Conteo por clase para plantas
conteo_registros_por_taxon(
  taxonKey = 6,
  facet = "classKey"
)
#> # A tibble: 35 × 2
#>    Clase             `Nº registros`
#>    <chr>             <chr>         
#>  1 Magnoliopsida     2.467.573     
#>  2 Liliopsida        516.127       
#>  3 Polypodiopsida    112.554       
#>  4 Bryopsida         106.258       
#>  5 Florideophyceae   41.582        
#>  6 Pinopsida         25.860        
#>  7 Jungermanniopsida 15.522        
#>  8 Lycopodiopsida    8.241         
#>  9 Ulvophyceae       7.407         
#> 10 Sphagnopsida      6.290         
#> # ℹ 25 more rows

# Solo observaciones humanas
conteo_registros_por_taxon(
  basisOfRecord = c("HUMAN_OBSERVATION")
)
#> # A tibble: 99 × 2
#>    Filo             `Nº registros`
#>    <chr>            <chr>         
#>  1 Chordata         48.424.070    
#>  2 Tracheophyta     15.031.315    
#>  3 Arthropoda       1.393.434     
#>  4 Actinobacteriota 146.335       
#>  5 Mollusca         76.575        
#>  6 Basidiomycota    73.792        
#>  7 Ascomycota       69.114        
#>  8 Proteobacteria   68.994        
#>  9 Acidobacteriota  57.547        
#> 10 Mycetozoa        53.916        
#> # ℹ 89 more rows
```
