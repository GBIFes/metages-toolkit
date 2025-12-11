# Instalar y cargar paquetes packages
pkgs <- c("rgbif", "readr", "dplyr")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}



# Lanzar los SPECIES LIST download
download_key_observation <- occ_download(
  pred("publishingCountry", "ES"),
  pred_in("basisOfRecord", c("HUMAN_OBSERVATION", "MACHINE_OBSERVATION")),
  format = "SPECIES_LIST")

cat("Download key generado: ", download_key_observation, "\n")
occ_download_wait(download_key_observation)

# --------------------------------------
# Only leaving uncounted basisOfRecord == Occurrence
# --------------------------------------

download_key_specimen <- occ_download(
  pred("publishingCountry", "ES"),
  pred_in("basisOfRecord", c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN",
                             "PRESERVED_SPECIMEN", "MATERIAL_SAMPLE",
                             "MATERIAL_CITATION")),
  format = "SPECIES_LIST")

cat("Download key generado: ", download_key_specimen, "\n")
occ_download_wait(download_key_specimen)


# Funcion para sacar taxonomia
sum_taxa <- function(download_key){
  
    # Descargar el archivo ZIP
    zip_file <- occ_download_get(download_key, overwrite = TRUE)
    
    # Importar como una tabla
    species_list <- occ_download_import(zip_file)
    
    species_list <- species_list %>%
      mutate(
        phylum = if_else(phylum == "" | is.na(phylum), "Unknown", phylum)
      )
    
    
    
    # Agrupar por reino
    kingdom_counts <- species_list %>%
      group_by(kingdom) %>%
      summarise(total_occurrences = sum(numberOfOccurrences, na.rm = TRUE),
                n_class = n_distinct(class, na.rm = TRUE),
                n_order = n_distinct(order, na.rm = TRUE),
                n_family = n_distinct(family, na.rm = TRUE),
                n_genus = n_distinct(genus, na.rm = TRUE),
                n_species = n_distinct(species, na.rm = TRUE),
                ) %>%
      arrange(desc(total_occurrences))  %>% 
      bind_rows(
        summarise(., 
                  kingdom = "TOTAL",
                  total_occurrences = sum(total_occurrences, na.rm = TRUE),
                  n_class = sum(n_class, na.rm = TRUE),
                  n_order = sum(n_order, na.rm = TRUE),
                  n_family = sum(n_family, na.rm = TRUE),
                  n_genus = sum(n_genus, na.rm = TRUE),
                  n_species = sum(n_species, na.rm = TRUE)
        )
      )
    
    # Agrupar por filos botanicos
    phylum_botanic_counts <- species_list %>%
      filter(kingdom == "Plantae") %>% # edit with other kingdoms
      group_by(phylum) %>%
      summarise(total_occurrences = sum(numberOfOccurrences, na.rm = TRUE)) %>%
      arrange(desc(total_occurrences)) %>% 
      bind_rows(
        summarise(., 
                  phylum = "TOTAL",
                  total_occurrences = sum(total_occurrences, na.rm = TRUE)))

    # Agrupar por filos zoologicos
    phylum_zoologic_counts <- species_list %>%
      filter(kingdom == "Animalia") %>% # edit with other kingdoms
      group_by(phylum) %>%
      summarise(total_occurrences = sum(numberOfOccurrences, na.rm = TRUE)) %>%
      arrange(desc(total_occurrences)) %>% 
      bind_rows(
        summarise(., 
                  phylum = "TOTAL",
                  total_occurrences = sum(total_occurrences, na.rm = TRUE)))

  return(list(kingdom_counts = kingdom_counts, 
              phylum_botanic_counts = phylum_botanic_counts,
              phylum_zoologic_counts = phylum_zoologic_counts))
}

# Resultados
obs <- sum_taxa(download_key_observation)
spec <- sum_taxa(download_key_specimen)




