# Database Terraform Configuration

This directory contains Terraform configuration for deploying MySQL and PostgreSQL Flexible Servers. MySQL is deployed in `eastus` and PostgreSQL is deployed in `eastus2`.

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions
- The main infrastructure (Resource Group and Key Vault) must be deployed first via the `main` module

## Directory Structure

```
db/
├── main.tf          # Database resources (MySQL, PostgreSQL, VNets, DNS zones)
├── variables.tf     # Variable definitions
├── outputs.tf       # Output definitions
├── dev/
│   ├── dev.conf     # Development backend configuration
│   └── dev.tfvars   # Development environment variables
├── stage/
│   ├── stage.conf   # Staging backend configuration
│   └── stage.tfvars # Staging environment variables
└── prod/
    ├── prod.conf    # Production backend configuration
    └── prod.tfvars  # Production environment variables
```

## Usage

### Initialize Terraform

```bash
cd db

# Development
terraform init -backend-config=dev/dev.conf

# Staging
terraform init -backend-config=stage/stage.conf

# Production
terraform init -backend-config=prod/prod.conf
```

### Plan Changes

```bash
# Development
terraform plan -var-file=dev/dev.tfvars

# Staging
terraform plan -var-file=stage/stage.tfvars

# Production
terraform plan -var-file=prod/prod.tfvars
```

### Apply Changes

```bash
# Development
terraform apply -var-file=dev/dev.tfvars

# Staging
terraform apply -var-file=stage/stage.tfvars

# Production
terraform apply -var-file=prod/prod.tfvars
```

## Deployment Order

1. **Deploy main infrastructure first** (Resource Group, Key Vault) via `../main/` directory
2. **Deploy databases** (this directory)
3. **Deploy Container Apps** (see `../container-apps/` directory) - Container Apps can reference database connection strings from Key Vault

## Database Locations

- **MySQL Flexible Server**: Deployed in `eastus` region
- **PostgreSQL Flexible Server**: Deployed in `eastus2` region

Each database has its own Virtual Network in its respective region.

## Outputs

After deployment, this configuration outputs:
- `resource_group_name` - Name of the resource group
- `postgresql_server_name` - Name of the PostgreSQL Flexible Server
- `postgresql_server_fqdn` - FQDN of the PostgreSQL Flexible Server
- `postgresql_database_name` - Name of the PostgreSQL database
- `postgresql_location` - Location of the PostgreSQL Flexible Server
- `mysql_server_name` - Name of the MySQL Flexible Server
- `mysql_server_fqdn` - FQDN of the MySQL Flexible Server
- `mysql_database_name` - Name of the MySQL database
- `mysql_location` - Location of the MySQL Flexible Server
- `postgresql_connection_string_secret_name` - Name of the Key Vault secret containing PostgreSQL connection string
- `mysql_connection_string_secret_name` - Name of the Key Vault secret containing MySQL connection string

## Key Vault Secrets

This module automatically stores database connection strings in Key Vault as secrets:
- `postgresql-connection-string` - PostgreSQL connection string
- `mysql-connection-string` - MySQL connection string

These secrets can be referenced by Container Apps or other services that need database access.

## Notes

- Both databases use Private DNS Zones for name resolution within their respective Virtual Networks
- Databases are configured with private endpoints only (no public network access)
- Backup retention is configurable per database
- SKU and storage configurations can be adjusted per environment

