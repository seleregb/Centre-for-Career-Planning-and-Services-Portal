# Required Permissions for Terraform Deployment

This document outlines the permissions required to deploy the Terraform configuration, either via an Azure DevOps service principal or your personal Azure account.

## Overview

Your Terraform configuration creates and manages the following Azure resources:
- Resource Groups
- Azure Container Registry (ACR)
- Key Vault (with access policies)
- App Service Plans (2)
- App Services / Linux Web Apps (2, with managed identities)
- Key Vault Secrets

Additionally, the backend requires:
- Storage Account (for Terraform state)
- Storage Container (for Terraform state)

---

## Managing Service Principals with Terraform

**Yes, you can manage service principals and permissions using Terraform!**

We provide a **bootstrap Terraform configuration** in the `bootstrap/` directory that automates the creation of service principals and role assignments.

### Quick Start with Terraform Bootstrap

Instead of manually creating service principals, you can use Terraform to create and manage them:

```bash
cd infra/terraform/bootstrap

# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Initialize and apply
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"

# 3. Save outputs (credentials)
terraform output -json > service-principal-credentials.json
```

The bootstrap configuration will automatically:
- ✅ Create Azure AD Application and Service Principal
- ✅ Generate client secret (password)
- ✅ Assign **Contributor** role at subscription level
- ✅ Assign **User Access Administrator** role (optional)
- ✅ Assign **Storage Blob Data Contributor** for Terraform state

**Important**: The bootstrap itself requires initial permissions:
- **Application Administrator** or **Global Administrator** (Azure AD) - to create service principals
- **User Access Administrator** (Azure subscription) - to assign roles

See [`bootstrap/README.md`](./bootstrap/README.md) for complete instructions.

### Benefits of Using Terraform for Service Principal Management

1. **Version Control**: Service principal configuration is stored in code
2. **Repeatability**: Easy to recreate for multiple environments
3. **Documentation**: Self-documenting through Terraform code
4. **Auditability**: Track changes through Terraform state
5. **Automation**: Integrates with CI/CD pipelines

---

## Required Azure RBAC Permissions

### Minimum Required Role

The service principal or user account needs **Contributor** role at the subscription level for creating and managing resources. However, for better security practices, we recommend a combination of specific roles.

### Recommended Permission Strategy

#### 1. **Subscription-Level Permissions**

Assign the following built-in roles at the **subscription level**:

##### Primary Role: **Contributor**
- **Scope**: Subscription
- **Purpose**: Create and manage most resources (Resource Groups, ACR, App Services, Key Vault, etc.)
- **Service Principal Assignment**:
  ```bash
  az role assignment create \
    --assignee <service-principal-object-id> \
    --role "Contributor" \
    --scope /subscriptions/<subscription-id>
  ```

##### Additional Role: **User Access Administrator** (Conditional)
- **Scope**: Subscription (or Resource Group level)
- **Purpose**: Required to grant Key Vault access policies to managed identities and other principals
- **Note**: Only needed if you don't already have this permission
- **Service Principal Assignment**:
  ```bash
  az role assignment create \
    --assignee <service-principal-object-id> \
    --role "User Access Administrator" \
    --scope /subscriptions/<subscription-id>
  ```

#### 2. **Storage Account Permissions (for Terraform Backend)**

For the Terraform state storage account:

##### Role: **Storage Blob Data Contributor**
- **Scope**: Storage Account (or specific container)
- **Purpose**: Read and write Terraform state files
- **Service Principal Assignment**:
  ```bash
  az role assignment create \
    --assignee <service-principal-object-id> \
    --role "Storage Blob Data Contributor" \
    --scope /subscriptions/<subscription-id>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/<storage-account-name>
  ```

Alternatively, if you only want access to the specific container:
```bash
az role assignment create \
  --assignee <service-principal-object-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/<storage-account-name>/blobServices/default/containers/tfstate
```

#### 3. **Azure AD Permissions**

The Terraform configuration uses `data.azurerm_client_config.current` which requires:
- Ability to read your own Azure AD object information
- This is typically available by default for authenticated principals

---

## Specific Resource Permissions Breakdown

### Resource Groups
- **Permission**: Create, Read, Update, Delete
- **Role**: Contributor (included)

### Azure Container Registry (ACR)
- **Permission**: Create, Read, Update, Delete, Manage admin credentials
- **Role**: Contributor (included)
- **Additional**: Admin user access if `acr_admin_enabled = true`

### Key Vault
- **Permission**: Create, Read, Update, Delete, Set access policies
- **Role**: Contributor (included)
- **Additional**: User Access Administrator (for setting access policies on managed identities)

### App Service Plans
- **Permission**: Create, Read, Update, Delete
- **Role**: Contributor (included)

### App Services / Web Apps
- **Permission**: Create, Read, Update, Delete, Manage app settings
- **Role**: Contributor (included)
- **Note**: The `null_resource` uses Azure CLI commands that require Web Apps Contributor permissions

### Managed Identities
- **Permission**: Create system-assigned managed identities (automatic with App Service creation)
- **Permission**: Read managed identity principal IDs (for Key Vault access policies)
- **Role**: Contributor (included)

### Key Vault Secrets
- **Permission**: Create, Read, Update, Delete secrets
- **Role**: Contributor (included)
- **Note**: Also requires Key Vault Access Policy permissions (handled by User Access Administrator role)

---

## Azure DevOps Service Principal Setup

### Creating a Service Principal

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "sp-terraform-ccps" \
  --role "Contributor" \
  --scopes /subscriptions/<subscription-id>

# Add User Access Administrator role (if needed)
az role assignment create \
  --assignee <service-principal-app-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<subscription-id>

# Add Storage Blob Data Contributor for state backend
az role assignment create \
  --assignee <service-principal-app-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/<storage-account-name>
```

### Store Credentials in Azure DevOps

1. Go to **Project Settings** → **Service connections**
2. Create a new **Azure Resource Manager** service connection
3. Choose **Service principal (manual)**
4. Enter:
   - Subscription ID
   - Subscription Name
   - Service Principal Client ID (from `az ad sp create-for-rbac`)
   - Service Principal Key (password from the command output)
   - Tenant ID
5. Save the service connection

### Update Pipeline Variables

Update your pipeline YAML to use the service connection:
```yaml
variables:
  azureSubscription: 'your-service-connection-name'
  terraformServiceConnection: 'your-terraform-service-connection'
```

---

## Alternative: Custom Role Definition

For more granular control, you can create a custom role with minimal permissions:

```json
{
  "Name": "Terraform CCPS Deployer",
  "Description": "Custom role for deploying CCPS Portal infrastructure",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.ContainerRegistry/registries/*",
    "Microsoft.KeyVault/vaults/*",
    "Microsoft.KeyVault/vaults/accessPolicies/*",
    "Microsoft.KeyVault/vaults/secrets/*",
    "Microsoft.Web/serverfarms/*",
    "Microsoft.Web/sites/*",
    "Microsoft.Web/sites/config/*",
    "Microsoft.ManagedIdentity/userAssignedIdentities/*",
    "Microsoft.Authorization/roleAssignments/write",
    "Microsoft.Authorization/roleAssignments/read",
    "Microsoft.Storage/storageAccounts/blobServices/containers/*",
    "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
  ],
  "NotActions": [],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*",
    "Microsoft.KeyVault/vaults/secrets/*"
  ],
  "AssignableScopes": [
    "/subscriptions/<subscription-id>"
  ]
}
```

Create the custom role:
```bash
az role definition create --role-definition @custom-role.json
```

---

## Verification

### Test Permissions

Before running Terraform, verify your permissions:

```bash
# Check current user/service principal permissions
az role assignment list --assignee <your-object-id-or-sp-app-id> --all

# Test storage account access (for state backend)
az storage blob list \
  --account-name <storage-account-name> \
  --container-name tfstate \
  --auth-mode login

# Test Key Vault access
az keyvault list --query "[].name"

# Test Resource Group creation (dry run - won't create)
az group exists --name test-rg-permissions-check
```

### Terraform Validation

```bash
# Initialize Terraform (tests backend access)
terraform init -backend-config="..."

# Validate configuration
terraform validate

# Plan deployment (tests read permissions)
terraform plan -var-file="stage/stage.tfvars"
```

---

## Troubleshooting Common Permission Issues

### Issue: "Authorization failed" when creating resources
- **Solution**: Ensure Contributor role is assigned at subscription or resource group level

### Issue: Cannot set Key Vault access policies
- **Solution**: Assign User Access Administrator role or ensure you have `Microsoft.Authorization/roleAssignments/write` permission

### Issue: Cannot access Terraform state in storage account
- **Solution**: Ensure Storage Blob Data Contributor role is assigned to the storage account/container

### Issue: `null_resource` local-exec fails with "webapp config appsettings set" error
- **Solution**: Ensure Contributor role includes Web Apps management permissions (should be included by default)

### Issue: Cannot read `azurerm_client_config` data source
- **Solution**: Ensure service principal/user has basic Azure AD read permissions (typically included by default)

---

## Security Best Practices

1. **Principle of Least Privilege**: Use custom roles with minimal required permissions instead of Contributor where possible
2. **Scope Permissions**: Assign roles at the resource group level rather than subscription level when possible
3. **Separate Service Principals**: Use different service principals for different environments (dev, stage, prod)
4. **Rotate Credentials**: Regularly rotate service principal passwords
5. **Audit Access**: Regularly review role assignments and remove unnecessary permissions
6. **Use Managed Identities**: Where possible, use managed identities instead of service principals

---

## Summary Checklist

### Option 1: Manual Setup
- [ ] Contributor role at subscription level (or resource group level)
- [ ] User Access Administrator role (for Key Vault access policies)
- [ ] Storage Blob Data Contributor role (for Terraform state backend)
- [ ] Service principal created (if using Azure DevOps)
- [ ] Service connection configured in Azure DevOps
- [ ] Permissions tested and verified

### Option 2: Terraform Bootstrap (Recommended)
- [ ] Bootstrap permissions verified (Application Administrator, User Access Administrator)
- [ ] Bootstrap Terraform configuration reviewed
- [ ] `terraform.tfvars` configured with correct values
- [ ] Bootstrap Terraform applied successfully
- [ ] Service principal credentials saved securely
- [ ] Service connection configured in Azure DevOps using bootstrap outputs
- [ ] Permissions tested and verified

---

## References

- [Azure RBAC Built-in Roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Terraform Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- [Azure DevOps Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)

