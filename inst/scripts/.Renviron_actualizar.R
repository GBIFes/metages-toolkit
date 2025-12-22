####### ATENCION ########
# Correr cada vez que queramos cambiar algo en el .Renviron de este proyecto 


# 1. Correr dentro del proyecto deseado
usethis::edit_r_environ("project")

# 2. Modificar documento que aparece tras la última línea

# 3. Guardar documento. Correr desde la consola con .Renviron abierto
rstudioapi::documentSave()

# 4. Hacer efectivos los cambios reiniciando la sesion de R
rstudioapi::restartSession()

