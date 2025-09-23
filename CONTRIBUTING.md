# Contribuir al Toolkit del Registro de Colecciones de GBIF

## Descripción General

Este repositorio es para uso interno de GBIF.ES para gestionar la base de datos del Registro de Colecciones. Las contribuciones deben seguir las directrices establecidas para mantener la calidad del código, la seguridad y la seguridad operacional.

## Antes de Contribuir

### Requisitos Previos

- Acceso a los sistemas internos de GBIF.ES
- Experiencia en programación R (versión 4.0+)
- Comprensión de operaciones de base de datos MySQL
- Familiaridad con la estructura de datos del Registro de Colecciones de GBIF

### Configuración Requerida

1. Completar entrenamiento de seguridad y revisar `SECURITY.md`
2. Obtener credenciales de base de datos apropiadas
3. Configurar entorno de desarrollo siguiendo `docs/setup.md`
4. Probar funcionalidad del toolkit en entorno TEST

## Flujo de Trabajo de Desarrollo

### 1. Configuración de Entorno

```bash
# Clonar repositorio
git clone https://github.com/GBIFes/metages-toolkit.git
cd metages-toolkit

# Set up R environment
# R will automatically activate renv if .Rprofile is present

# Configure database connections
cp config/test_config.R.template config/test_config.R
# Edit with your TEST credentials (never commit actual credentials)

# Test setup
Rscript scripts/run_exploration.R TEST
```

### 2. Branch Strategy

- `main` - Production-ready code
- `develop` - Integration branch for new features
- `feature/*` - Individual feature development
- `hotfix/*` - Critical fixes for production

### 3. Making Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Follow Coding Standards**
   - Use meaningful variable and function names
   - Include comprehensive documentation
   - Follow R style guidelines (tidyverse style preferred)
   - Add error handling for all database operations

3. **Test Changes**
   ```bash
   # Always test on TEST environment first
   Rscript scripts/run_exploration.R TEST
   Rscript scripts/run_qc_checks.R TEST
   ```

4. **Document Changes**
   - Update relevant README files
   - Add examples for new functionality
   - Update `docs/usage.md` if user-facing changes

## Code Standards

### R Code Style

```r
# Function naming: snake_case
analyze_collection_trends <- function(connection, time_period = "month") {
  # Function body
}

# Variable naming: snake_case
database_connection <- setup_database_connection("TEST")

# Constants: UPPER_CASE
DEFAULT_BATCH_SIZE <- 100

# Use explicit library calls
library(DBI)
library(dplyr)

# Document functions with roxygen2
#' Analyze Collection Trends
#' 
#' @param connection Database connection object
#' @param time_period Character. Time period for analysis
#' @return List with trend analysis results
#' @export
```

### Error Handling

```r
# Always use tryCatch for database operations
result <- tryCatch({
  # Database operation
  dbGetQuery(connection, query)
}, error = function(e) {
  logerror(paste("Operation failed:", e$message))
  return(NULL)
})
```

### Logging

```r
# Use appropriate log levels
loginfo("Starting operation")
logwarn("Potential issue detected")
logerror("Operation failed")
logdebug("Detailed debugging information")
```

## Testing Requirements

### Unit Testing

```r
# Test database connections
test_connection(connection)

# Test data validation
validation_result <- validate_update_data(connection, table_name, test_data)
stopifnot(validation_result$validation_passed)

# Test functionality with sample data
```

### Integration Testing

```bash
# Test complete workflows
Rscript scripts/run_exploration.R TEST output FALSE
Rscript scripts/run_qc_checks.R TEST output completeness FALSE
```

### Safety Testing

- Always test updates on TEST environment
- Verify backup and rollback functionality
- Test error handling scenarios
- Validate data integrity after operations

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