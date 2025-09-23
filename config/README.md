# Configuration Templates

This directory contains configuration templates for database connections via SSH tunnels.

## Files:
- `prod_config.R.template`: Template for production database configuration
- `test_config.R.template`: Template for test database configuration

## Setup Instructions:

1. Copy the template files and remove the `.template` extension:
   ```bash
   cp prod_config.R.template prod_config.R
   cp test_config.R.template test_config.R
   ```

2. Edit the configuration files with your actual SSH and database credentials.

3. **IMPORTANT**: Never commit the actual config files (`prod_config.R` and `test_config.R`) to version control as they contain sensitive credentials. These files are already listed in `.gitignore`.

## SSH Tunnel Configuration

This toolkit uses SSH tunnels to securely connect to the MySQL database. The connection flow is:

```
R Script -> Local ODBC (port 3307) -> SSH Tunnel -> Remote MySQL (port 3306)
```

### Required SSH Setup:

1. **SSH Key**: Ensure you have SSH private key access to `mola.gbif.es:22002`
2. **ODBC Driver**: Install MySQL ODBC driver on your system
   - Check available drivers: `odbc::odbcListDrivers()`
3. **Network Access**: Ensure you can reach the SSH server from your location

### Configuration Parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `ssh_host` | SSH server hostname | `"mola.gbif.es"` |
| `ssh_port` | SSH server port | `22002` |
| `ssh_user` | Your SSH username | `"your_username"` |
| `ssh_keyfile` | Path to SSH private key | `"~/.ssh/id_rsa"` |
| `local_port` | Local tunnel port | `3307` |
| `remote_host` | Database server behind tunnel | `"localhost"` |
| `remote_port` | Remote database port | `3306` |
| `odbc_driver` | ODBC driver name | `"MySQL ODBC 9.4 ANSI Driver"` |

## External Credentials (Optional)

You can use external credential files for additional security:

1. Create external config file (outside git repository)
2. Uncomment and configure the `EXTERNAL_CONFIG_FILE` section in templates
3. Store sensitive data (`UID`, `gbif_wp_pass`) in external file

## Security Notes:
- Configuration files containing actual credentials are excluded from git via `.gitignore`
- SSH private keys should be properly secured with appropriate file permissions
- Only users with proper SSH and database credentials should have access
- Consider using SSH agent for key management in production environments