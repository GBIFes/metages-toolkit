# Instalar y cargar paquetes packages
pkgs <- c("tidygeocoder")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}

#Conectar R a Metages con conectar_metages.R


# Extraer lugares nuevos
# dfs <- dbGetQuery(con, "SELECT DISTINCT c.town
#                         FROM colecciones c 
#                         LEFT JOIN metages_towns mt 
#                         ON c.town = mt.town 
#                         WHERE mt.town IS NULL
#                         AND c.town <> ''")

# Extraer lugares nuevos
dfs <- dbGetQuery(con, "SELECT DISTINCT ma.town 
                        FROM metages_address ma
                        LEFT JOIN metages_body mb 
                        ON ma.address_id = mb.address_fk 
                        WHERE ma.town NOT IN (SELECT mt.town FROM metages_towns mt)
                        AND private = 0")

# Extraer todos los lugares para recalcular coordenadas
dfs <- dbGetQuery(con, "SELECT DISTINCT town
	                      FROM metages_towns mt ")



# Extraer coordenadas para cada lugar (Filtra registros espanholes)
coords <- geo(address = paste0(as.character(dfs$town),
                               ", España"),
              method = "osm",   # usa Nominatim
              full_results = TRUE)


# Crear datos listos para insertar en Metages
coords_clean <- coords %>%
                mutate(address = sub(", España$", "", address),
                       to_insert = paste0("('",
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
                                          )) %>% 
                filter (address != "Sin dirección") 


# Usar esto para identificar las regiones de cada localidad
# Asegurarse de que las coordenadas son de los lugares que queremos y no de homonimos!!
coords_clean %>% select(address, display_name)

# Extraer datos para insertar en Metages
cat(coords_clean$to_insert, sep = "\n")


# Anhadir el resultado del "cat" a esta actualizacion debajo de VALUES
# Hacer manualmente:
# - Anhadir region a cada localidad
# - Quitar ultima coma
# - Asegurarse de que el hardcoded country e iso_country_fk son correctos
dta <- dbExecute(con, "INSERT INTO metages_towns (town, region, country, iso_country_fk, LAT, `LONG`)
                        VALUES
                        
                        ")


