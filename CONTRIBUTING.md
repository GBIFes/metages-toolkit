# Guía de Contribución al Toolkit del Registro de Colecciones de GBIF España

## Descripción General

Este repositorio es para uso interno exclusivo de GBIF.ES para gestionar la base de datos del Registro de Colecciones de GBIF España. Las contribuciones deben seguir las directrices establecidas para mantener la calidad del código, la seguridad y la estabilidad operacional.

## Antes de Contribuir

### Requisitos Previos

- Acceso autorizado a los sistemas internos de GBIF.ES
- Experiencia en programación R (versión 4.0 o superior)
- Comprensión de operaciones de base de datos MySQL
- Familiaridad con la estructura de datos del Registro de Colecciones de GBIF España
- Conocimiento del protocolo de túneles SSH para conexiones seguras

### Configuración Requerida

1. Completar entrenamiento de seguridad y revisar `SECURITY.md`
2. Obtener credenciales de base de datos apropiadas para entornos PROD y TEST
3. Configurar entorno de desarrollo siguiendo `docs/setup.md`
4. Configurar túneles SSH según las instrucciones del equipo técnico
5. Probar funcionalidad del toolkit en entorno TEST antes de cualquier desarrollo

## Flujo de Trabajo de Desarrollo

### 1. Configuración de Entorno

```bash
# Clonar repositorio
git clone https://github.com/GBIFes/metages-toolkit.git
cd metages-toolkit

# Configurar entorno R
# R activará automáticamente renv si .Rprofile está presente

# Configurar conexiones de base de datos
cp config/test_config.R.template config/test_config.R
# Editar con tus credenciales de TEST (nunca comprometer credenciales reales)

# Probar configuración
Rscript scripts/run_exploration.R TEST
```

### 2. Estrategia de Ramas

- `main` - Código listo para producción
- `develop` - Rama de integración para nuevas características
- `feature/*` - Desarrollo de características individuales
- `hotfix/*` - Correcciones críticas para producción

### 3. Realizar Cambios

1. **Crear Rama de Característica**
   ```bash
   git checkout -b feature/nombre-de-tu-caracteristica
   ```

2. **Seguir Estándares de Código**
   - Usar nombres de variables y funciones significativos en español
   - Incluir documentación comprensiva en español
   - Seguir guías de estilo R (preferencia por estilo tidyverse)
   - Añadir manejo de errores para todas las operaciones de base de datos

3. **Probar Cambios**
   ```bash
   # Siempre probar en entorno TEST primero
   Rscript scripts/run_exploration.R TEST
   Rscript scripts/run_qc_checks.R TEST
   ```

4. **Documentar Cambios**
   - Actualizar archivos README relevantes
   - Añadir ejemplos para nueva funcionalidad
   - Actualizar `docs/usage.md` si hay cambios visibles al usuario

## Estándares de Código

### Estilo de Código R

```r
# Nombres de función: snake_case (en español descriptivo)
analizar_tendencias_colecciones <- function(conexion, periodo_tiempo = "mes") {
  # Cuerpo de la función
}

# Nombres de variables: snake_case (en español)
conexion_base_datos <- setup_database_connection("TEST")

# Constantes: MAYÚSCULAS (en español)
TAMAÑO_LOTE_PREDETERMINADO <- 100

# Usar llamadas explícitas de librería
library(DBI)
library(dplyr)

# Documentar funciones con roxygen2 en español
#' Analizar Tendencias de Colecciones
#' 
#' @param conexion Objeto de conexión a base de datos
#' @param periodo_tiempo Character. Período de tiempo para análisis
#' @return Lista con resultados de análisis de tendencias
#' @export
```

### Manejo de Errores

```r
# Siempre usar tryCatch para operaciones de base de datos
resultado <- tryCatch({
  # Operación de base de datos
  dbGetQuery(conexion, consulta)
}, error = function(e) {
  logerror(paste("Operación falló:", e$message))
  return(NULL)
})
```

### Registro de Logs

```r
# Usar niveles de log apropiados
loginfo("Iniciando operación")
logwarn("Problema potencial detectado")
logerror("Operación falló")
logdebug("Información detallada de depuración")
```

## Requisitos de Pruebas

### Pruebas Unitarias

```r
# Probar conexiones de base de datos
test_connection(conexion)

# Probar validación de datos
resultado_validacion <- validate_update_data(conexion, nombre_tabla, datos_prueba)
stopifnot(resultado_validacion$validation_passed)

# Probar funcionalidad con datos de muestra
```

### Pruebas de Integración

```bash
# Probar flujos de trabajo completos
Rscript scripts/run_exploration.R TEST output FALSE
Rscript scripts/run_qc_checks.R TEST output completeness FALSE
```

### Pruebas de Seguridad

- Siempre probar actualizaciones en entorno TEST
- Verificar funcionalidad de respaldo y rollback
- Probar escenarios de manejo de errores
- Validar integridad de datos después de operaciones

## Security Requirements

### Code Security

- **Never hard-code credentials** in source code
- **Validate all inputs** before database operations
- **Use parameterized queries** to prevent SQL injection
- **Log operations** without exposing sensitive data

### Data Protection

- Handle personal data according to privacy policies
- Use appropriate access controls
- Encrypt sensitive data in transit and at rest
- Follow data retention policies

## Review Process

### Pull Request Requirements

1. **Description**: Clear description of changes and rationale
2. **Testing**: Evidence of testing on TEST environment
3. **Documentation**: Updated documentation for changes
4. **Security Review**: Security implications addressed
5. **Code Quality**: Follows coding standards and best practices

### Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass on TEST environment
- [ ] Documentation updated
- [ ] Security considerations addressed
- [ ] No credentials or sensitive data in code
- [ ] Error handling implemented
- [ ] Logging appropriate
- [ ] Backwards compatibility maintained

## Deployment

### To Development Environment

```bash
# Merge to develop branch
git checkout develop
git merge feature/your-feature

# Test integration
Rscript scripts/run_qc_checks.R TEST
```

### To Production

1. **Staging Review**: Full testing on staging environment
2. **Security Approval**: Security team approval for production changes
3. **Change Management**: Follow change management procedures
4. **Deployment Window**: Deploy during scheduled maintenance window
5. **Post-Deployment**: Verify functionality and monitor for issues

## Documentation Standards

### Code Documentation

- Document all functions with roxygen2 comments
- Include parameter descriptions and return values
- Provide usage examples
- Document error conditions

### User Documentation

- Update `docs/usage.md` for user-facing changes
- Include examples in documentation
- Update README files for significant changes
- Maintain up-to-date installation instructions

## Issue Reporting

### Bug Reports

Include the following information:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (R version, database version)
- Error messages and logs
- Sample data (if applicable and non-sensitive)

### Feature Requests

Include the following information:
- Use case description
- Proposed solution
- Alternative approaches considered
- Impact assessment
- Implementation timeline

## Release Process

### Version Numbering

Use semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes

### Release Notes

Document:
- New features
- Bug fixes
- Breaking changes
- Security updates
- Migration instructions

## Support and Communication

### Internal Channels

- Technical discussions: Internal team meetings
- Code reviews: GitHub pull requests
- Issue tracking: GitHub issues
- Documentation: Repository wiki/docs

### Emergency Procedures

For critical issues:
1. Contact on-call technical team member
2. Create emergency hotfix branch
3. Implement minimal fix
4. Fast-track review process
5. Deploy with monitoring

## Resources

### Documentation

- [Setup Guide](docs/setup.md)
- [Usage Guide](docs/usage.md)
- [Security Policy](SECURITY.md)

### External Resources

- [R Style Guide](https://style.tidyverse.org/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [GBIF API Documentation](https://www.gbif.org/developer)

---

**Questions?** Contact the GBIF.ES technical team for guidance.