# Política de Seguridad

## Descripción General

El Toolkit del Registro de Colecciones de GBIF maneja credenciales sensibles de base de datos y realiza operaciones en datos de producción. Este documento describe las políticas y directrices de seguridad para asegurar un uso seguro.

## Reportar Vulnerabilidades de Seguridad

Si descubres una vulnerabilidad de seguridad, repórtala de forma privada al equipo técnico de GBIF.ES. No crees issues públicos para vulnerabilidades de seguridad.

## Directrices de Seguridad

### 1. Gestión de Credenciales

**NUNCA hacer commit de credenciales de base de datos al control de versiones:**
- Usar plantillas de configuración (archivos `.template`) en el repositorio
- Mantener archivos de configuración reales (`prod_config.R`, `test_config.R`) solo localmente
- Estos archivos son automáticamente excluidos vía `.gitignore`
- Considerar usar variables de entorno para seguridad adicional

### 2. Separación de Entornos

**Siempre distinguir entre entornos:**
- Usar entorno `TEST` para desarrollo y pruebas
- Requerir confirmación explícita para operaciones `PROD`
- Probar todas las operaciones en `TEST` antes de ejecutar en `PROD`
- Mantener credenciales separadas para cada entorno

### 3. Acceso a Base de Datos

**Seguir principio de menor privilegio:**
- Solo personal autorizado debe tener credenciales de base de datos
- Usar credenciales de solo lectura cuando sea posible para exploración y análisis
- Limitar acceso de escritura a operaciones específicas y personal
- Revisar y rotar contraseñas de base de datos regularmente

### 4. Respaldo y Recuperación

**Proteger contra pérdida de datos:**
- Respaldos automáticos se crean antes de operaciones de actualización
- Verificar integridad de respaldos antes de proceder con actualizaciones
- Mantener procedimientos de rollback para operaciones críticas
- Almacenar respaldos de forma segura con controles de acceso apropiados

### 5. Registro de Auditoría

**Mantener registro comprensivo:**
- Todas las operaciones de base de datos se registran con marcas de tiempo
- Archivos de registro contienen detalles de operación e identificación de usuario
- Revisar registros regularmente para actividad inusual
- Retener registros de acuerdo a políticas organizacionales

### 6. Seguridad de Red

**Conexiones seguras a base de datos:**
- Usar conexiones SSL/TLS cuando estén disponibles
- Conectar a través de VPN para acceso remoto
- Restringir acceso a base de datos a direcciones IP específicas
- Monitorear tráfico de red para anomalías

### 7. Seguridad de Código

**Seguir prácticas de codificación segura:**
- Validar todos los datos de entrada antes de operaciones de base de datos
- Usar consultas parametrizadas para prevenir inyección SQL
- Implementar manejo de errores apropiado sin exponer información sensible
- Revisión regular de código para vulnerabilidades de seguridad

## Salvaguardas de Producción

### Lista de Verificación Pre-Producción

Antes de ejecutar operaciones en producción:

- [ ] Operación probada exitosamente en entorno TEST
- [ ] Datos validados y respaldo creado
- [ ] Operación revisada por segundo miembro del equipo
- [ ] Autorización apropiada obtenida para cambios de producción
- [ ] Plan de rollback preparado y probado

### Requisitos de Operación en Producción

1. **Confirmación Explícita**: Todas las operaciones de producción requieren confirmación del usuario
2. **Creación de Respaldo**: Respaldos automáticos antes de cualquier modificación de datos
3. **Registro**: Todas las operaciones registradas con registro de auditoría completo
4. **Monitoreo**: Monitoreo en tiempo real durante operaciones críticas
5. **Rollback Listo**: Capacidad de rollback inmediato si se detectan problemas

## Seguridad de Archivos

### Archivos Sensibles (Nunca hacer commit a Git)

```
config/prod_config.R       # Credenciales de base de datos de producción
config/test_config.R       # Credenciales de base de datos de prueba
logs/*.log                 # Archivos de registro pueden contener datos sensibles
output/*sensitive*         # Archivos de salida con datos sensibles
*.csv                      # Exportaciones de datos pueden contener información sensible
*.rds                      # Archivos de datos R pueden contener información sensible
```

### Permisos de Archivos

Configurar permisos restrictivos en archivos sensibles:

```bash
chmod 600 config/prod_config.R
chmod 600 config/test_config.R
chmod 755 logs/
chmod 644 logs/*.log
```

## Respuesta a Incidentes

### En caso de incidente de seguridad:

1. **Respuesta Inmediata**
   - Desconectar sistemas afectados de la red si es necesario
   - Preservar evidencia (registros, estado del sistema)
   - Notificar al equipo de seguridad de GBIF.ES inmediatamente

2. **Evaluación**
   - Determinar alcance e impacto del incidente
   - Identificar datos y sistemas afectados
   - Documentar cronología de eventos

3. **Contención**
   - Implementar medidas de contención inmediatas
   - Cambiar credenciales comprometidas
   - Aplicar parches de seguridad si es aplicable

4. **Recuperación**
   - Restaurar desde respaldos limpios si es necesario
   - Verificar integridad del sistema antes de resumir operaciones
   - Actualizar medidas de seguridad para prevenir recurrencia

5. **Post-Incidente**
   - Conducir revisión exhaustiva post-incidente
   - Actualizar políticas y procedimientos de seguridad
   - Proporcionar entrenamiento adicional si es necesario

## Cumplimiento

Este toolkit debe cumplir con:

- Políticas de compartir datos y acceso de GBIF
- Requisitos institucionales de protección de datos
- Regulaciones de privacidad aplicables
- Estándares internos de seguridad

## Entrenamiento y Concienciación

Todos los usuarios deben:

- Completar entrenamiento de concienciación de seguridad
- Entender y seguir estas políticas de seguridad
- Reportar preocupaciones de seguridad prontamente
- Participar en revisiones regulares de seguridad

## Revisiones Regulares de Seguridad

- Revisión mensual de registros de acceso
- Actualizaciones trimestrales de política de seguridad
- Pruebas de penetración anuales (si es aplicable)
- Pruebas regulares de respaldo y recuperación

## Contacto

Para preguntas o preocupaciones de seguridad, contactar:
- Equipo Técnico de GBIF.ES
- Oficial de Seguridad Institucional
- Administrador de Base de Datos

---

**Recordar: La seguridad es responsabilidad de todos. En caso de duda, preguntar antes de proceder.**