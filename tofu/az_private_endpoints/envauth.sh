#!/bin/bash
# usage: source ./envauth.sh <key-vault-name>
# pulls the service-principal credentials for this root from azure key vault
KV_NAME="${1:?usage: source ./envauth.sh <key-vault-name>}"

export ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_SUBSCRIPTION_ID ARM_TENANT_ID ARM_ACCESS_KEY
ARM_CLIENT_ID=$(az keyvault secret show --name tf-clientid --vault-name "$KV_NAME" --query value -o tsv)
ARM_CLIENT_SECRET=$(az keyvault secret show --name tf-clientsecret --vault-name "$KV_NAME" --query value -o tsv)
ARM_SUBSCRIPTION_ID=$(az keyvault secret show --name tf-subscriptionid --vault-name "$KV_NAME" --query value -o tsv)
ARM_TENANT_ID=$(az keyvault secret show --name tf-tenantid --vault-name "$KV_NAME" --query value -o tsv)

# for storing state in blob storage - the storage account key:
ARM_ACCESS_KEY=$(az keyvault secret show --name tf-state-key --vault-name "$KV_NAME" --query value -o tsv)
