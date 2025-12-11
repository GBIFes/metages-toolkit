# Instalar y cargar paquetes packages
pkgs <- c("tidygeocoder")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}

#Conectar R a Metages con conectar_metages.R


# Extraer lugares nuevos
dfs <- dbGetQuery(con, "SELECT DISTINCT c.town
                        FROM colecciones c 
                        LEFT JOIN metages_towns mt 
                        ON c.town = mt.town 
                        WHERE mt.town IS NULL
                        AND c.town <> ''")

# Extraer todos los lugares para recalcular coordenadas
dfs <- dbGetQuery(con, "SELECT DISTINCT town
	                      FROM metages_towns mt ")


coords <- geo(address = as.character(dfs$town),
              method = "osm",   # usa Nominatim
              full_results = TRUE) 



coords_clean <- coords %>%
                mutate(to_insert = paste0("('",
                                          address,
                                          "', ",
                                          "'', ",
                                          "'SPAIN', ",
                                          199, # Spain
                                          ",",
                                          "'",
                                          lat,
                                          "', ",
                                          "'",
                                          long,
                                          "'),"
                                          )) 


cat(coords_clean$to_insert, sep = "\n")
