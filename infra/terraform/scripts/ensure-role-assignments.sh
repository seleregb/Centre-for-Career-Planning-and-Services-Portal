#!/bin/bash

# Script to ensure Azure role assignments exist, skipping if they already do
# Usage: ./ensure-role-assignments.sh --subscription|--resource-group --principal <principal> --roles <role1,role2,...> [--resource-group-name <rg-name>] [--subscription-id <sub-id>]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SCOPE_TYPE=""
PRINCIPAL=""
ROLES=""
RESOURCE_GROUP_NAME=""
SUBSCRIPTION_ID=""

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Ensure Azure role assignments exist, skipping if they already do.

OPTIONS:
    --subscription                    Assign roles at subscription level
    --resource-group                  Assign roles at resource group level
    --principal <principal>           Service principal name or object ID
    --roles <role1,role2,...>         Comma-separated list of role names
    --resource-group-name <name>      Resource group name (required for --resource-group)
    --subscription-id <id>            Subscription ID (optional, uses current if not specified)
    -h, --help                        Show this help message

EXAMPLES:
    # Subscription-level assignments
    $0 --subscription --principal "tfAzureDevOps" --roles "Contributor,User Access Administrator"

    # Resource group-level assignments
    $0 --resource-group --principal "tfAzureDevOps" --roles "Contributor" --resource-group-name "rg-ccps-portal-dev"

    # With explicit subscription ID
    $0 --subscription --principal "tfAzureDevOps" --roles "Contributor" --subscription-id "/subscriptions/12345678-1234-1234-1234-123456789012"
EOF
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --subscription)
            SCOPE_TYPE="subscription"
            shift
            ;;
        --resource-group)
            SCOPE_TYPE="resource-group"
            shift
            ;;
        --principal)
            PRINCIPAL="$2"
            shift 2
            ;;
        --roles)
            ROLES="$2"
            shift 2
            ;;
        --resource-group-name)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        --subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$SCOPE_TYPE" ]]; then
    echo -e "${RED}Error: Must specify either --subscription or --resource-group${NC}" >&2
    usage
fi

if [[ -z "$PRINCIPAL" ]]; then
    echo -e "${RED}Error: --principal is required${NC}" >&2
    usage
fi

if [[ -z "$ROLES" ]]; then
    echo -e "${RED}Error: --roles is required${NC}" >&2
    usage
fi

if [[ "$SCOPE_TYPE" == "resource-group" && -z "$RESOURCE_GROUP_NAME" ]]; then
    echo -e "${RED}Error: --resource-group-name is required when using --resource-group${NC}" >&2
    usage
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI (az) is not installed${NC}" >&2
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure. Please run 'az login' first${NC}" >&2
    exit 1
fi

# Get subscription ID if not provided
if [[ -z "$SUBSCRIPTION_ID" ]]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo -e "${BLUE}Using current subscription: ${SUBSCRIPTION_ID}${NC}"
else
    # Normalize subscription ID format
    if [[ ! "$SUBSCRIPTION_ID" =~ ^/subscriptions/ ]]; then
        SUBSCRIPTION_ID="/subscriptions/${SUBSCRIPTION_ID}"
    fi
fi

# Get principal object ID
echo -e "${BLUE}Resolving principal: ${PRINCIPAL}${NC}"
if [[ "$PRINCIPAL" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    # Already an object ID (GUID format)
    PRINCIPAL_OBJECT_ID="$PRINCIPAL"
    echo -e "${GREEN}Using provided object ID: ${PRINCIPAL_OBJECT_ID}${NC}"
else
    # Try to resolve as service principal name
    PRINCIPAL_OBJECT_ID=$(az ad sp list --display-name "$PRINCIPAL" --query "[0].id" -o tsv 2>/dev/null || echo "")
    if [[ -z "$PRINCIPAL_OBJECT_ID" ]]; then
        echo -e "${RED}Error: Could not find service principal with name: ${PRINCIPAL}${NC}" >&2
        echo -e "${YELLOW}Hint: You can also provide the object ID directly${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Resolved to object ID: ${PRINCIPAL_OBJECT_ID}${NC}"
fi

# Determine scope
if [[ "$SCOPE_TYPE" == "subscription" ]]; then
    SCOPE="/subscriptions/$(echo "$SUBSCRIPTION_ID" | sed 's|/subscriptions/||')"
    SCOPE_DESC="subscription"
else
    SCOPE="/subscriptions/$(echo "$SUBSCRIPTION_ID" | sed 's|/subscriptions/||')/resourceGroups/${RESOURCE_GROUP_NAME}"
    SCOPE_DESC="resource group '${RESOURCE_GROUP_NAME}'"
fi

echo -e "${BLUE}Scope: ${SCOPE_DESC}${NC}"
echo -e "${BLUE}Scope path: ${SCOPE}${NC}"
echo ""

# Convert comma-separated roles to array
IFS=',' read -ra ROLE_ARRAY <<< "$ROLES"

# Track statistics
CREATED=0
SKIPPED=0
FAILED=0

# Process each role
for ROLE in "${ROLE_ARRAY[@]}"; do
    ROLE=$(echo "$ROLE" | xargs) # Trim whitespace
    
    echo -e "${BLUE}Checking role: ${ROLE}${NC}"
    
    # Check if role assignment already exists
    EXISTING_COUNT=$(az role assignment list \
        --scope "$SCOPE" \
        --assignee "$PRINCIPAL_OBJECT_ID" \
        --role "$ROLE" \
        --query "length(@)" \
        -o tsv 2>/dev/null) || EXISTING_COUNT="0"
    
    # Ensure EXISTING_COUNT is a valid number
    if [[ ! "$EXISTING_COUNT" =~ ^[0-9]+$ ]]; then
        EXISTING_COUNT="0"
    fi
    
    if [[ "$EXISTING_COUNT" -gt 0 ]]; then
        echo -e "${YELLOW}  ✓ Role assignment already exists, skipping${NC}"
        ((SKIPPED++))
    else
        echo -e "${BLUE}  → Creating role assignment...${NC}"
        # Capture both stdout and stderr to show errors if creation fails
        if CREATE_OUTPUT=$(az role assignment create \
            --scope "$SCOPE" \
            --assignee "$PRINCIPAL_OBJECT_ID" \
            --role "$ROLE" \
            --output none 2>&1); then
            echo -e "${GREEN}  ✓ Role assignment created successfully${NC}"
            ((CREATED++))
        else
            echo -e "${RED}  ✗ Failed to create role assignment${NC}" >&2
            # Show the actual error message
            if [[ -n "$CREATE_OUTPUT" ]]; then
                echo -e "${RED}    Error: ${CREATE_OUTPUT}${NC}" >&2
            fi
            ((FAILED++))
        fi
    fi
    echo ""
done

# Print summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary:${NC}"
echo -e "  ${GREEN}Created: ${CREATED}${NC}"
echo -e "  ${YELLOW}Skipped: ${SKIPPED}${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}Failed: ${FAILED}${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Exit with error if any failed
# if [[ $FAILED -gt 0 ]]; then
#     exit 1
# fi

exit 0

