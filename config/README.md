# Configuration Templates

This directory contains configuration templates for database connections.

## Files:
- `prod_config.R.template`: Template for production database configuration
- `test_config.R.template`: Template for test database configuration

## Setup Instructions:

1. Copy the template files and remove the `.template` extension:
   ```bash
   cp prod_config.R.template prod_config.R
   cp test_config.R.template test_config.R
   ```

2. Edit the configuration files with your actual database credentials.

3. **IMPORTANT**: Never commit the actual config files (`prod_config.R` and `test_config.R`) to version control as they contain sensitive credentials. These files are already listed in `.gitignore`.

## Security Notes:
- Configuration files containing actual credentials are excluded from git via `.gitignore`
- Only users with proper database credentials should have access to these files
- Consider using environment variables or secure credential management systems in production