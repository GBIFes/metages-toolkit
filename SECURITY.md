# Security Policy

## Overview

The GBIF Collections Registry Toolkit handles sensitive database credentials and performs operations on production data. This document outlines security policies and guidelines to ensure safe usage.

## Reporting Security Vulnerabilities

If you discover a security vulnerability, please report it privately to the GBIF.ES technical team. Do not create public issues for security vulnerabilities.

## Security Guidelines

### 1. Credential Management

**NEVER commit database credentials to version control:**
- Use configuration templates (`.template` files) in the repository
- Keep actual configuration files (`prod_config.R`, `test_config.R`) local only
- These files are automatically excluded via `.gitignore`
- Consider using environment variables for additional security

### 2. Environment Separation

**Always distinguish between environments:**
- Use `TEST` environment for development and testing
- Require explicit confirmation for `PROD` operations
- Test all operations on `TEST` before running on `PROD`
- Maintain separate credentials for each environment

### 3. Database Access

**Follow principle of least privilege:**
- Only authorized personnel should have database credentials
- Use read-only credentials when possible for exploration and analysis
- Limit write access to specific operations and personnel
- Regularly review and rotate database passwords

### 4. Backup and Recovery

**Protect against data loss:**
- Automatic backups are created before update operations
- Verify backup integrity before proceeding with updates
- Maintain rollback procedures for critical operations
- Store backups securely with appropriate access controls

### 5. Audit Trail

**Maintain comprehensive logging:**
- All database operations are logged with timestamps
- Log files contain operation details and user identification
- Review logs regularly for unusual activity
- Retain logs according to organizational policies

### 6. Network Security

**Secure database connections:**
- Use SSL/TLS connections when available
- Connect through VPN for remote access
- Restrict database access to specific IP addresses
- Monitor network traffic for anomalies

### 7. Code Security

**Follow secure coding practices:**
- Validate all input data before database operations
- Use parameterized queries to prevent SQL injection
- Implement proper error handling without exposing sensitive information
- Regular code review for security vulnerabilities

## Production Safeguards

### Pre-Production Checklist

Before running operations on production:

- [ ] Operation tested successfully on TEST environment
- [ ] Data validated and backup created
- [ ] Operation reviewed by second team member
- [ ] Appropriate authorization obtained for production changes
- [ ] Rollback plan prepared and tested

### Production Operation Requirements

1. **Explicit Confirmation**: All production operations require user confirmation
2. **Backup Creation**: Automatic backups before any data modifications
3. **Logging**: All operations logged with full audit trail
4. **Monitoring**: Real-time monitoring during critical operations
5. **Rollback Ready**: Immediate rollback capability if issues detected

## File Security

### Sensitive Files (Never commit to Git)

```
config/prod_config.R       # Production database credentials
config/test_config.R       # Test database credentials
logs/*.log                 # Log files may contain sensitive data
output/*sensitive*         # Output files with sensitive data
*.csv                      # Data exports may contain sensitive information
*.rds                      # R data files may contain sensitive information
```

### File Permissions

Set restrictive permissions on sensitive files:

```bash
chmod 600 config/prod_config.R
chmod 600 config/test_config.R
chmod 755 logs/
chmod 644 logs/*.log
```

## Incident Response

### In case of security incident:

1. **Immediate Response**
   - Disconnect affected systems from network if necessary
   - Preserve evidence (logs, system state)
   - Notify GBIF.ES security team immediately

2. **Assessment**
   - Determine scope and impact of incident
   - Identify affected data and systems
   - Document timeline of events

3. **Containment**
   - Implement immediate containment measures
   - Change compromised credentials
   - Apply security patches if applicable

4. **Recovery**
   - Restore from clean backups if necessary
   - Verify system integrity before resuming operations
   - Update security measures to prevent recurrence

5. **Post-Incident**
   - Conduct thorough post-incident review
   - Update security policies and procedures
   - Provide additional training if needed

## Compliance

This toolkit must comply with:

- GBIF data sharing and access policies
- Institutional data protection requirements
- Applicable privacy regulations
- Internal security standards

## Training and Awareness

All users must:

- Complete security awareness training
- Understand and follow these security policies
- Report security concerns promptly
- Participate in regular security reviews

## Regular Security Reviews

- Monthly review of access logs
- Quarterly security policy updates
- Annual penetration testing (if applicable)
- Regular backup and recovery testing

## Contact

For security questions or concerns, contact:
- GBIF.ES Technical Team
- Institutional Security Officer
- Database Administrator

---

**Remember: Security is everyone's responsibility. When in doubt, ask before proceeding.**