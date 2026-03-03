# Con el objetivo de no manipular el codigo de informe.qmd que genera el informe,
# ponemos a disposicion del gestor del informe este documento donde se recopilan
# las metricas que se introducen manualmente en el informe.

# ESTAS METRICAS NO DEBEN SER CALCULADAS, ya que hacen referencia a los datos
# del informe anterior en su mayoria, por lo que es mas sencillo copiarlas a mano, 
# extrayendolas de la ultima version publicada del informe.

# Hay una excepcion, que son metricas extraidas de GBIF.org

# Para que no haya problemas, debe mantenerse el mismo formato para cada metrica.


metricas_manuales <- list(
  
# ------------------------------------------------------------
# Metricas GBIF.org
# ------------------------------------------------------------

# Extraer de https://www.gbif.org/the-gbif-network = "Voting participants" + "Associate country participants"
n_gbif_paises = 69,      

# Extraer de https://www.gbif.org/the-gbif-network = "Other associate participants"
n_gbif_organizaciones = 42,

# Ranking de España en GBIF.org. Extraer de get_top_publishing_countries_gbif()
n_ranking_gbifes = "undécimo",


# ------------------------------------------------------------
# Metricas simples Informe GBIF.es anterior
# ------------------------------------------------------------

# Numero edicion del informe actual y anterior
n_edicion_informe_actual = "septima",
n_edicion_informe_anterior = "sexta",

# Fecha de extraccion de datos para generacion del informe anterior
anno_data_informe_anterior = 2019,

# Fecha de publicacion del informe anterior
anno_informe_anterior = 2021,
mes_anno_informe_anterior = "octubre de 2021",


# ------------------------------------------------------------
# Metricas de tablas Informe GBIF.es anterior
# ------------------------------------------------------------
# Se extraen manualmente de las tablas del informe anteriormente publicado 
# que contienen esta informacion.


# Numero de entidades, entidades publicadoras, colecciones-y-bases-de-datos
# recursos y registros del informe anterior.
n_entidades_informe_anterior = 229, 
n_entidades_informe_anterior_pub = 104, 
n_colbd_informe_anterior = 474,
n_recursos_informe_anterior = 308, 
n_registros_informe_anterior = 32367320, 

# Numero de colecciones-y-bases-de-datos del informe anterior divididas por:
# disciplina y subdisciplina 
inf_ant_n_colbd_total = "474",
inf_ant_n_colbd_zoo = "(192)",
inf_ant_n_colbd_inv = "103",
inf_ant_n_colbd_ver = "70",
inf_ant_n_colbd_invver = "19",
inf_ant_n_colbd_bot = "(201)",
inf_ant_n_colbd_pla = "163",
inf_ant_n_colbd_alg = "14",
inf_ant_n_colbd_hong = "24",
inf_ant_n_colbd_botmix = "NA",
inf_ant_n_colbd_micro = "8",
inf_ant_n_colbd_paleo = "44",
inf_ant_n_colbd_mix = "29",

# Numero de registros del informe anterior divididos por:
# disciplina y subdisciplina 
inf_ant_n_reg_total = "32.367.320",
inf_ant_n_reg_zoo = "(13.331.336)",
inf_ant_n_reg_inv = "1.064.701",
inf_ant_n_reg_ver = "12.199.676",
inf_ant_n_reg_invver = "66.959",
inf_ant_n_reg_bot = "(15.893.174)",
inf_ant_n_reg_pla = "15.430.831",
inf_ant_n_reg_alg = "31.868",
inf_ant_n_reg_hong = "430.475",
inf_ant_n_reg_botmix = "NA",
inf_ant_n_reg_micro = "12.176",
inf_ant_n_reg_paleo = "34.637",
inf_ant_n_reg_mix = "3.095.997"

)

# Guardar como RDS
saveRDS(metricas_manuales, paste0(here::here(), 
                                  "/inst/reports/data/metricas_manuales.rds"))

