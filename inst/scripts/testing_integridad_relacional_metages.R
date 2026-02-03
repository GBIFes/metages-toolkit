# Cargar DBI para conexiones a bases de datos
library(DBI)

# Establecer la conexion
con <- conectar_metages()$con

# Explorar la base de datos MetaGES. Esta lista muestra las tablas y vistas disponibles
dbListTables(con)

# Extraer los datos seleccionados como objeto de R. Admite queries complejos.
ispartof <- dbGetQuery(con, 
                 "SELECT * FROM metages_ispartof")


body <- dbGetQuery(con, 
                 "SELECT * FROM metages_body")


# Hijos sin padre
df <- dbGetQuery(con, 
                   "SELECT i.*, b.*
                   FROM metages_ispartof i
                   left join metages_body b
                   on i.parent_body_fk = b.body_id
                   where i.child_body_fk 
                   not in (select body_id from metages_body)")


# Padres sin hijo
df2 <- dbGetQuery(con, 
                 "SELECT i.*, b.*
                   FROM metages_ispartof i
                   left join metages_body b
                   on i.child_body_fk = b.body_id
                   where i.parent_body_fk 
                   not in (select body_id from metages_body)")






library(dplyr)


df <- body



# Desconectar de MetaGES
dbDisconnect(con)