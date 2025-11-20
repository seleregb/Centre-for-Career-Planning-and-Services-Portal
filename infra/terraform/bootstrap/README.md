# Bootstrap Service Principal Configuration

This directory contains Terraform configuration to create and manage service principals with the required permissions for deploying the CCPS Portal infrastructure.

## Overview

This bootstrap configuration creates:
- Azure AD Application and Service Principal
- Service Principal password (client secret)
- Required RBAC role assignments:
  - **Contributor** (subscription level)
  - **User Access Administrator** (subscription level, optional)
  - **Storage Blob Data Contributor** (Terraform state storage account)

## Bootstrap Problem (Chicken-and-Egg)

**Important**: To run this Terraform configuration, you need initial permissions to:
- Create Azure AD applications and service principals
- Assign RBAC roles

These permissions are typically:
- **Application Administrator** or **Global Administrator** (Azure AD) - to create service principals
- **User Access Administrator** (Azure subscription) - to assign roles

Once this bootstrap is complete, the created service principal can be used for all future Terraform deployments without requiring elevated permissions.

## Prerequisites

### Required Permissions

The user/service principal running this bootstrap needs:

1. **Azure AD Permissions**:
   - **Application Administrator** role OR
   - **Global Administrator** role

2. **Azure Subscription Permissions**:
   - **User Access Administrator** role (at subscription level)
   - **Contributor** role (at subscription level) - for reading subscription data

### Required Resources

- Terraform state storage account must already exist
- Resource group for Terraform state must already exist

If these don't exist, create them first:

```bash
# Create resource group for Terraform state
az group create --name rg-terraform-state --location canadacentral

# Create storage account
az storage account create \
  --name stterraformstate \
  --resource-group rg-terraform-state \
  --location canadacentral \
  --sku Standard_LRS

# Create storage container
az storage container create \
  --name tfstate \
  --account-name stterraformstate
```

## Setup

### 1. Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
service_principal_name = "sp-terraform-ccps-prod"
environment = "prod"
terraform_state_storage_account_name = "stterraformstate"
terraform_state_resource_group_name = "rg-terraform-state"
assign_user_access_admin = true
password_rotation_days = 0
```

### 2. Authenticate

Log in with your Azure account that has the required permissions:

```bash
az login
```

Or, if using a service principal:

```bash
az login --service-principal \
  --username <client-id> \
  --password <client-secret> \
  --tenant <tenant-id>
```

### 3. Initialize Terraform

```bash
cd bootstrap
terraform init
```

### 4. Plan Deployment

```bash
terraform plan -var-file="terraform.tfvars"
```

### 5. Apply Configuration

```bash
terraform apply -var-file="terraform.tfvars"
```

### 6. Save Outputs

**IMPORTANT**: The output will include the service principal client secret. Save this securely!

```bash
# Save outputs to a file (be careful with secrets!)
terraform output -json > service-principal-credentials.json

# Or save individual values
terraform output service_principal_client_id > sp-client-id.txt
terraform output -raw service_principal_client_secret > sp-client-secret.txt
terraform output service_principal_tenant_id > sp-tenant-id.txt
```

**Security Note**: 
- Store credentials securely (Azure Key Vault, Azure DevOps variable groups, etc.)
- Never commit secrets to version control
- Use Azure Key Vault or secure secret management for production

## Using the Service Principal

### For Local Terraform Deployment

Create environment variables:

```bash
export ARM_CLIENT_ID=$(terraform output -raw service_principal_client_id)
export ARM_CLIENT_SECRET=$(terraform output -raw service_principal_client_secret)
export ARM_SUBSCRIPTION_ID=$(terraform output -raw subscription_id)
export ARM_TENANT_ID=$(terraform output -raw service_principal_tenant_id)
```

Then run Terraform in your main configuration:

```bash
cd ../main
terraform init -backend-config="..."
terraform plan -var-file="stage/stage.tfvars"
terraform apply -var-file="stage/stage.tfvars"
```

### For Azure DevOps

1. Go to **Project Settings** → **Service connections**
2. Create new **Azure Resource Manager** service connection
3. Choose **Service principal (manual)**
4. Use the values from Terraform outputs:
   - **Subscription ID**: `terraform output -raw subscription_id`
   - **Subscription Name**: From Azure portal
   - **Service Principal Client ID**: `terraform output -raw service_principal_client_id`
   - **Service Principal Key**: `terraform output -raw service_principal_client_secret`
   - **Tenant ID**: `terraform output -raw service_principal_tenant_id`

5. Name the connection (e.g., `terraform-service-connection`)

6. Update your pipeline YAML to use the service connection:

```yaml
variables:
  terraformServiceConnection: 'terraform-service-connection'

stages:
  - stage: DeployInfrastructure
    displayName: 'Deploy Infrastructure'
    jobs:
      - job: TerraformDeploy
        steps:
          - task: TerraformTaskV4@4
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: '$(terraformServiceConnection)'
              # ... other configuration
```

## Multi-Environment Setup

You can create separate service principals for each environment:

### Development

```bash
terraform apply \
  -var-file="terraform.tfvars" \
  -var="service_principal_name=sp-terraform-ccps-dev" \
  -var="environment=dev"
```

### Staging

```bash
terraform apply \
  -var-file="terraform.tfvars" \
  -var="service_principal_name=sp-terraform-ccps-stage" \
  -var="environment=stage"
```

### Production

```bash
terraform apply \
  -var-file="terraform.tfvars" \
  -var="service_principal_name=sp-terraform-ccps-prod" \
  -var="environment=prod"
```

Or use separate workspace directories:

```
bootstrap/
  dev/
    terraform.tfvars
  stage/
    terraform.tfvars
  prod/
    terraform.tfvars
```

## Scope-Limited Permissions

For enhanced security, you can limit the service principal to specific resource groups:

```hcl
resource_group_scopes = {
  dev   = "rg-ccps-portal-dev"
  stage = "rg-ccps-portal-stage"
  prod  = "rg-ccps-portal-prod"
}
```

When using this approach:
- The Contributor role will be assigned at resource group level instead of subscription level
- You may still need User Access Administrator at subscription level for Key Vault access policies
- Ensure resource groups exist before running bootstrap

## Password Rotation

The service principal password can be rotated manually or automatically:

### Manual Rotation

```bash
# Generate new password
terraform apply -var-file="terraform.tfvars" -replace="azuread_service_principal_password.terraform"
```

### Automatic Rotation

Set `password_rotation_days` in `terraform.tfvars`:

```hcl
password_rotation_days = 90  # Rotate every 90 days
```

Note: Automatic rotation requires additional automation (e.g., scheduled Terraform runs).

## Verification

After creating the service principal, verify it works:

```bash
# Get the credentials from outputs
CLIENT_ID=$(terraform output -raw service_principal_client_id)
CLIENT_SECRET=$(terraform output -raw service_principal_client_secret)
TENANT_ID=$(terraform output -raw service_principal_tenant_id)

# Test login
az login --service-principal \
  --username $CLIENT_ID \
  --password $CLIENT_SECRET \
  --tenant $TENANT_ID

# Verify permissions
az role assignment list --assignee $CLIENT_ID --all

# Test resource group creation (will be cleaned up)
az group create --name test-rg-verification --location eastus
az group delete --name test-rg-verification --yes --no-wait
```

## Cleanup

To remove the service principal and all role assignments:

```bash
terraform destroy -var-file="terraform.tfvars"
```

**Warning**: This will delete the service principal. Make sure you have backups of credentials or another way to manage your infrastructure.

## Troubleshooting

### Error: "Insufficient privileges to complete the operation"

- Verify you have **Application Administrator** or **Global Administrator** in Azure AD
- Verify you have **User Access Administrator** at subscription level

### Error: "Storage account not found"

- Ensure the Terraform state storage account exists
- Verify the storage account name and resource group name in `terraform.tfvars`

### Error: "Role assignment already exists"

- The service principal may have already been created manually
- Check existing role assignments: `az role assignment list --assignee <client-id>`
- Consider importing existing resources or using `terraform import`

## Security Best Practices

1. **Separate Service Principals**: Use different service principals for each environment
2. **Scope Permissions**: Use resource group-level permissions when possible
3. **Secure Secret Storage**: Store service principal secrets in Azure Key Vault or Azure DevOps secure variables
4. **Regular Rotation**: Rotate passwords regularly (every 90 days recommended)
5. **Audit Access**: Regularly review role assignments and remove unnecessary permissions
6. **Least Privilege**: Only assign the minimum required permissions
7. **Monitoring**: Enable Azure Monitor alerts for service principal sign-ins

## Next Steps

After successfully running the bootstrap:

1. Store service principal credentials securely
2. Configure Azure DevOps service connections
3. Update pipeline YAML files to use the new service connection
4. Test deployment with the service principal
5. Document the service principal usage for your team

