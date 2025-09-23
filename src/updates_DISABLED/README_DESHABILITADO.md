# Módulo de Actualizaciones - DESHABILITADO

⚠️ **IMPORTANTE**: Este módulo está deshabilitado en la versión actual del toolkit.

## Motivo

En esta primera fase del Toolkit del Registro de Colecciones GBIF España, solo se implementa funcionalidad de **lectura y análisis** de datos. Las operaciones de actualización y modificación de la base de datos están deshabilitadas por seguridad.

## Funcionalidad Disponible

✅ **Operaciones permitidas:**
- Exploración de esquemas y datos
- Análisis de calidad de datos
- Generación de reportes
- Visualizaciones y estadísticas
- Exportación de datos

❌ **Operaciones deshabilitadas:**
- Actualización de registros
- Inserción de nuevos datos
- Eliminación de registros
- Modificación de esquemas
- Operaciones de escritura en general

## Activación Futura

Para habilitar funcionalidad de actualización en futuras versiones:

1. Renombrar directorio `src/updates_DISABLED` a `src/updates`
2. Renombrar script `scripts/run_updates.R.DISABLED` a `scripts/run_updates.R`
3. Actualizar `.Rprofile` para incluir módulo de actualizaciones
4. Realizar pruebas exhaustivas en entorno TEST antes de usar en PROD

## Seguridad

Esta medida de seguridad asegura que:
- No se modifiquen datos accidentalmente durante análisis
- Se mantenga integridad de datos en PROD
- Se establezca flujo de trabajo seguro para análisis de datos
- Se require autorización explícita para operaciones de escritura

Para más información, consulta la documentación en `docs/` o contacta al administrador del sistema.