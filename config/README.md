# Plantillas de Configuración

Este directorio contiene plantillas de configuración para conexiones de base de datos a través de túneles SSH.

## Archivos:
- `prod_config.R.template`: Plantilla para configuración de base de datos de producción
- `test_config.R.template`: Plantilla para configuración de base de datos de pruebas

## Instrucciones de Configuración:

1. Copia los archivos de plantilla y elimina la extensión `.template`:
   ```bash
   cp prod_config.R.template prod_config.R
   cp test_config.R.template test_config.R
   ```

2. Edita los archivos de configuración con tus credenciales SSH y de base de datos reales.

3. **IMPORTANTE**: Nunca confirmes los archivos de configuración reales (`prod_config.R` y `test_config.R`) en control de versiones ya que contienen credenciales sensibles. Estos archivos ya están listados en `.gitignore`.

## Configuración de Túnel SSH

Este toolkit utiliza túneles SSH para conectarse de forma segura a la base de datos MySQL. El flujo de conexión es:

```
Script R -> ODBC Local (puerto 3307) -> Túnel SSH -> MySQL Remoto (puerto 3306)
```

### Configuración SSH Requerida:

1. **Clave SSH**: Asegúrate de tener acceso con clave privada SSH a `mola.gbif.es:22002`
2. **Driver ODBC**: Instala el driver ODBC de MySQL en tu sistema
   - Verificar drivers disponibles: `odbc::odbcListDrivers()`
3. **Acceso de Red**: Asegúrate de poder alcanzar el servidor SSH desde tu ubicación

### Parámetros de Configuración:

| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `ssh_host` | Nombre del servidor SSH | `"mola.gbif.es"` |
| `ssh_port` | Puerto del servidor SSH | `22002` |
| `ssh_user` | Tu nombre de usuario SSH | `"tu_usuario"` |
| `ssh_keyfile` | Ruta a la clave privada SSH | `"~/.ssh/id_rsa"` |
| `local_port` | Puerto del túnel local | `3307` |
| `remote_host` | Servidor de BD detrás del túnel | `"localhost"` |
| `remote_port` | Puerto de BD remota | `3306` |
| `odbc_driver` | Nombre del driver ODBC | `"MySQL ODBC 9.4 ANSI Driver"` |

## Credenciales Externas (Opcional)

Puedes usar archivos de credenciales externos para seguridad adicional:

1. Crea archivo de configuración externo (fuera del repositorio git)
2. Descomenta y configura la sección `EXTERNAL_CONFIG_FILE` en las plantillas
3. Almacena datos sensibles (`UID`, `gbif_wp_pass`) en archivo externo

## Notas de Seguridad:
- Los archivos de configuración que contienen credenciales reales están excluidos de git via `.gitignore`
- Las claves privadas SSH deben estar debidamente aseguradas con permisos de archivo apropiados
- Solo usuarios con credenciales SSH y de base de datos apropiadas deben tener acceso
- Considera usar SSH agent para manejo de claves en entornos de producción