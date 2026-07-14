#!/bin/bash
# OIDC bootstrap: grant a user-assigned managed identity the roles it needs to
# run IaC deploys from GitHub Actions — Storage Blob Data Owner + Storage
# Account Contributor on the tfstate storage account (read/write state and
# toggle its firewall), and Contributor on the target resource group.
# Imported from sanarte's infrastructure/terraform/scripts/setup_permissions.sh;
# already fully parameterised via arguments.
set -e

# Check if required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <storage-account-name> <storage-rg-name> <managed-identity-principal-id> <target-rg-name>"
    echo "Example: $0 tfstatedevxyz rg-tfstate-dev 12345678-1234-1234-1234-123456789012 rg-myapp-dev"
    exit 1
fi

# Assign variables from arguments
STORAGE_ACCOUNT_NAME=$1
STORAGE_RG_NAME=$2
MANAGED_IDENTITY_ID=$3
TARGET_RG_NAME=$4

echo "Setting up permissions for managed identity..."
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Storage Resource Group: $STORAGE_RG_NAME"
echo "Managed Identity: $MANAGED_IDENTITY_ID"
echo "Target Resource Group: $TARGET_RG_NAME"

# Get Storage Account ID
echo "Getting storage account ID..."
STORAGE_ACCOUNT_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$STORAGE_RG_NAME" \
  --query id --output tsv)

echo "Storage Account ID: $STORAGE_ACCOUNT_ID"

# Get Target Resource Group ID
echo "Getting target resource group ID..."
TARGET_RG_ID=$(az group show \
  --name "$TARGET_RG_NAME" \
  --query id --output tsv)

echo "Target Resource Group ID: $TARGET_RG_ID"

# Assign Storage Blob Data Owner role
echo "Assigning Storage Blob Data Owner role..."
az role assignment create \
  --assignee "$MANAGED_IDENTITY_ID" \
  --role "Storage Blob Data Owner" \
  --scope "$STORAGE_ACCOUNT_ID"

# Assign Storage Account Contributor role
echo "Assigning Storage Account Contributor role..."
az role assignment create \
  --assignee "$MANAGED_IDENTITY_ID" \
  --role "Storage Account Contributor" \
  --scope "$STORAGE_ACCOUNT_ID"

# Assign Contributor role on target resource group
echo "Assigning Contributor role on target resource group..."
az role assignment create \
  --assignee "$MANAGED_IDENTITY_ID" \
  --role "Contributor" \
  --scope "$TARGET_RG_ID"

echo "Verifying role assignments..."
echo "Roles for storage account:"
az role assignment list \
  --assignee "$MANAGED_IDENTITY_ID" \
  --scope "$STORAGE_ACCOUNT_ID" \
  --output table

echo "Roles for target resource group:"
az role assignment list \
  --assignee "$MANAGED_IDENTITY_ID" \
  --scope "$TARGET_RG_ID" \
  --output table

echo "Setup complete!"
echo ""
echo "If you need to remove these permissions, use the following commands:"
echo ""
echo "az role assignment delete --assignee $MANAGED_IDENTITY_ID --role \"Storage Blob Data Owner\" --scope $STORAGE_ACCOUNT_ID"
echo "az role assignment delete --assignee $MANAGED_IDENTITY_ID --role \"Storage Account Contributor\" --scope $STORAGE_ACCOUNT_ID"
echo "az role assignment delete --assignee $MANAGED_IDENTITY_ID --role \"Contributor\" --scope $TARGET_RG_ID"
