# Main Terraform Configuration

This directory contains a single `main.tf` file that is configured per environment using `.tfvars` and `.conf` files.

## File Structure

```
main/
├── main.tf          # Single main Terraform configuration file
├── variables.tf     # Variable definitions
├── outputs.tf       # Output definitions
├── dev.tfvars       # Development environment variables
├── dev.conf         # Development backend configuration
├── stage.tfvars     # Staging environment variables
├── stage.conf       # Staging backend configuration
├── prod.tfvars      # Production environment variables
├── prod.conf        # Production backend configuration
└── .gitignore       # Git ignore rules
```

## Usage

### Initialize Terraform for an Environment

```bash
# Development
terraform init -backend-config=dev.conf

# Staging
terraform init -backend-config=stage.conf

# Production
terraform init -backend-config=prod.conf
```

### Plan Changes

```bash
# Development
terraform plan -var-file=dev.tfvars

# Staging
terraform plan -var-file=stage.tfvars

# Production
terraform plan -var-file=prod.tfvars
```

### Apply Changes

```bash
# Development
terraform apply -var-file=dev.tfvars

# Staging
terraform apply -var-file=stage.tfvars

# Production
terraform apply -var-file=prod.tfvars
```

## Environment-Specific Configuration

### Development (dev.tfvars)
- Basic/Free tier resources
- Relaxed security settings
- Resource group deletion allowed

### Staging (stage.tfvars)
- Standard tier resources
- Production-like settings
- Resource group deletion prevented

### Production (prod.tfvars)
- Premium tier resources
- Enhanced security (purge protection, network ACLs)
- Resource group deletion prevented

## Backend Configuration

Each environment has its own `.conf` file that specifies:
- Resource group for Terraform state
- Storage account name
- Container name
- State file key (dev/terraform.tfstate, stage/terraform.tfstate, prod/terraform.tfstate)

## Secrets Management

Sensitive values like `mongodb_atlas_connection_string` and `jwt_secret` should be provided via:
1. Environment variables: `TF_VAR_mongodb_atlas_connection_string` and `TF_VAR_jwt_secret`
2. Terraform Cloud/Enterprise variables
3. Or uncomment and fill in the `.tfvars` files (not recommended for production)

**Important**: Never commit `.tfvars` files with actual secrets to version control.

## Serverless Databases

The main module includes support for two serverless databases:

### PostgreSQL Flexible Server (Serverless)
- **Tier**: Burstable (B-series) - cost-effective serverless-like scaling
- **Default SKU**: `B_Standard_B1ms` (1 vCore, 2GB RAM)
- **Storage**: Minimum 32 GB (32768 MB)
- **Network**: Private endpoint with VNet integration

### MySQL Flexible Server (Serverless)
- **Tier**: Burstable (B-series) - cost-effective serverless-like scaling
- **Default SKU**: `Standard_B1ms` (1 vCore, 2GB RAM)
- **Storage**: Minimum 20 GB with auto-grow enabled
- **Network**: Private endpoint with VNet integration

### Enabling Databases

To enable either database, uncomment and configure the relevant section in your environment's `.tfvars` file:

1. **Set unique server names** (must be globally unique across Azure)
2. **Configure admin credentials** (preferably via environment variables)
3. **Set database names** and other configuration options

Example for enabling PostgreSQL in `dev.tfvars`:

```hcl
# PostgreSQL Serverless Database Configuration
postgresql_server_name      = "ccps-portal-psql-dev"  # Must be globally unique
postgresql_admin_username   = "psqladmin"
# postgresql_admin_password = ""  # Provide via TF_VAR_postgresql_admin_password
postgresql_database_name    = "ccpsportal"
postgresql_version          = "16"
postgresql_sku_name         = "B_Standard_B1ms"
```

### Connection Strings

Once the databases are deployed, connection strings are automatically stored in Azure Key Vault:
- **PostgreSQL**: Secret name `PostgreSQLConnectionString`
- **MySQL**: Secret name `MySQLConnectionString`

Retrieve connection strings using:

```bash
# PostgreSQL
az keyvault secret show --vault-name <key-vault-name> --name PostgreSQLConnectionString --query value -o tsv

# MySQL
az keyvault secret show --vault-name <key-vault-name> --name MySQLConnectionString --query value -o tsv
```

### Network Configuration

Both databases use private endpoints with:
- Dedicated subnets within a VNet (10.0.1.0/24 for PostgreSQL, 10.0.2.0/24 for MySQL)
- Private DNS zones for name resolution
- No public access (enhanced security)

### Cost Optimization

The databases are configured for cost-effective serverless operation:
- **Burstable tier**: Only pay for compute when active
- **Auto-pause**: Not available, but Burstable tier provides cost savings
- **Backup retention**: 7 days (configurable)
- **High availability**: Disabled (can be enabled for production if needed)

