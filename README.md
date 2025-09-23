# GBIF Spain Collections Registry Toolkit

Repositorio de uso interno para leer, analizar y actualizar el Registro de Colecciones de GBIF.ES

## Descripción

Este toolkit proporciona un conjunto completo de herramientas en R para gestionar y analizar la base de datos del Registro de Colecciones de GBIF España (GBIF.ES). El registro es una base de datos privada de metadatos de colecciones españolas, visible públicamente en https://gbif.es/registro-colecciones/. 

El toolkit está diseñado para trabajar con entornos de producción (PROD) y pruebas (TEST) de forma segura y eficiente, proporcionando acceso controlado a los metadatos de las colecciones registradas en España.

## Funcionalidades Principales

### 🔍 Exploración de Base de Datos
- Análisis de estructura de tablas y esquemas
- Generación de estadísticas descriptivas
- Evaluación de calidad de datos
- Informes completos de exploración

### ✅ Control de Calidad
- Verificación de completitud de datos
- Validación de consistencia e integridad referencial
- Comprobación de formatos y restricciones
- Aplicación de reglas de negocio específicas de GBIF

### 📊 Análisis de Datos
- Análisis de tendencias temporales
- Cobertura geográfica e institucional
- Identificación de patrones en los datos
- Métricas de rendimiento y salud de datos

### 📝 Actualizaciones Seguras
- Validación previa de datos de actualización
- Creación automática de respaldos
- Operaciones de actualización individuales y masivas
- Registro de auditoría de todas las operaciones

## Estructura del Repositorio

```
metages-toolkit/
├── README.md                      # Este archivo
├── .gitignore                     # Archivos excluidos del control de versiones
├── config/                        # Configuraciones de base de datos
│   ├── README.md                  # Guía de configuración
│   ├── prod_config.R.template     # Plantilla para configuración de PROD
│   └── test_config.R.template     # Plantilla para configuración de TEST
├── src/                           # Código fuente
│   ├── connection/                # Módulo de conexión a BD
│   │   ├── README.md
│   │   └── db_connection.R
│   ├── exploration/               # Módulo de exploración
│   │   ├── README.md
│   │   └── data_exploration.R
│   ├── quality_control/           # Módulo de control de calidad
│   │   ├── README.md
│   │   └── qc_checks.R
│   ├── analysis/                  # Módulo de análisis
│   │   ├── README.md
│   │   └── data_analysis.R
│   └── updates/                   # Módulo de actualizaciones
│       ├── README.md
│       └── db_updates.R
├── scripts/                       # Scripts de ejecución principales
│   ├── run_exploration.R          # Exploración de BD
│   ├── run_qc_checks.R           # Control de calidad
│   ├── run_analysis.R            # Análisis de datos
│   └── run_updates.R             # Actualizaciones de BD
└── docs/                         # Documentación
    ├── setup.md                  # Guía de instalación y configuración
    └── usage.md                  # Guía de uso detallada
```

## Instalación Rápida

### Prerrequisitos

- R (versión 4.0.0 o superior)
- Acceso a las bases de datos MySQL del Registro de Colecciones de GBIF España
- Credenciales válidas para entornos PROD y TEST
- Acceso SSH a `mola.gbif.es:22002`

### Configuración

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/GBIFes/metages-toolkit.git
   cd metages-toolkit
   ```

2. **Instalar dependencias de R:**
   ```r
   install.packages(c("DBI", "odbc", "ssh", "pool", "dplyr", "ggplot2", 
                      "logging", "uuid", "jsonlite", "lubridate"))
   ```

3. **Configurar conexiones a BD:**
   ```bash
   # Copiar y editar plantillas de configuración
   cp config/prod_config.R.template config/prod_config.R
   cp config/test_config.R.template config/test_config.R
   
   # Editar con tus credenciales SSH y BD (¡NUNCA las subas a git!)
   # Los archivos de configuración ya están en .gitignore
   ```

   **Configuración SSH requerida:**
   - Host SSH: `mola.gbif.es:22002`
   - Clave privada SSH configurada
   - Túnel local puerto 3307 -> remoto puerto 3306
   - Driver ODBC MySQL instalado

4. **Crear directorios de salida:**
   ```bash
   mkdir -p output logs plots
   ```

## Uso Básico

### Exploración de la Base de Datos
```bash
# Explorar entorno de TEST
Rscript scripts/run_exploration.R TEST

# Explorar entorno de PROD
Rscript scripts/run_exploration.R PROD
```

### Control de Calidad
```bash
# Ejecutar todas las verificaciones en TEST
Rscript scripts/run_qc_checks.R TEST

# Verificaciones específicas
Rscript scripts/run_qc_checks.R TEST output completeness,consistency
```

### Análisis de Datos
```bash
# Dashboard completo de análisis
Rscript scripts/run_analysis.R TEST

# Análisis específicos
Rscript scripts/run_analysis.R PROD output trends,coverage csv
```

### Actualizaciones de Base de Datos
```bash
# ¡SIEMPRE probar primero en TEST!
Rscript scripts/run_updates.R TEST validate datos_actualizacion.csv
Rscript scripts/run_updates.R TEST update_collection datos_actualizacion.csv

# Solo después de pruebas exitosas en PROD
Rscript scripts/run_updates.R PROD update_collection datos_actualizacion.csv
```

## Seguridad y Mejores Prácticas

### 🔒 Seguridad de Credenciales
- Las credenciales de BD **NUNCA** se suben al repositorio
- Los archivos de configuración están en `.gitignore`
- Se recomienda usar variables de entorno para credenciales
- Acceso restringido solo a personal autorizado

### 🧪 Flujo de Desarrollo
1. **Siempre probar en TEST** antes que en PROD
2. **Validar datos** antes de cualquier actualización
3. **Crear respaldos** antes de cambios importantes
4. **Monitorear logs** para detectar errores
5. **Documentar cambios** significativos

### 📊 Gestión de Datos
- Evaluaciones regulares de calidad
- Monitoreo de tendencias para detección temprana de problemas
- Procedimientos documentados de actualización
- Control de versiones para cambios importantes

## Documentación Detallada

- **[Guía de Configuración](docs/setup.md)** - Instalación paso a paso y configuración detallada
- **[Guía de Uso](docs/usage.md)** - Instrucciones completas de uso y ejemplos avanzados
- **[Registro de Colecciones GBIF.ES](https://gbif.es/registro-colecciones/)** - Interfaz pública del registro
- **Documentación de módulos** - Cada directorio `src/` contiene su propio README.md

## Soporte Técnico

Para soporte técnico o preguntas:

1. Consulta la documentación en `docs/`
2. Revisa los archivos de log para detalles de errores
3. Contacta al equipo técnico de GBIF.ES
4. Abre un issue en GitHub (solo para temas no sensibles)

## Contribución

Este es un repositorio de uso interno de GBIF.ES. Las contribuciones deben seguir:

1. Proceso de revisión interno
2. Pruebas exhaustivas en entorno TEST
3. Documentación actualizada
4. Cumplimiento de estándares de seguridad

## Licencia

Uso interno de GBIF.ES. Consulta con el equipo técnico para detalles de licencia.

---

**⚠️ IMPORTANTE**: Este toolkit maneja datos sensibles del Registro de Colecciones de GBIF España. Siempre seguir los procedimientos de seguridad establecidos y probar en entorno TEST antes de ejecutar operaciones en PROD.
