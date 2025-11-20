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

