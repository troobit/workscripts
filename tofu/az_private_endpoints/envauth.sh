#!/bin/bash
# Run this command in your environement, and sub <KEY VAULT NAME> --name variables per requirements
export ARM_CLIENT_ID=$(az keyvault secret show --name tf-clientid --vault-name <KEY VAULT NAME> --query value -o tsv)
export ARM_CLIENT_SECRET=$(az keyvault secret show --name tf-clientsecret --vault-name <KEY VAULT NAME> --query value -o tsv)
export ARM_SUBSCRIPTION_ID=$(az keyvault secret show --name tf-subscriptionid --vault-name <KEY VAULT NAME> --query value -o tsv)
export ARM_TENANT_ID=$(az keyvault secret show --name tf-tenantid --vault-name <KEY VAULT NAME> --query value -o tsv)

# For storing TF state in blob storage - use the storage account key:
export ARM_ACCESS_KEY=$(az keyvault secret show --name tf-state-key --vault-name <KEY VAULT NAME> --query value -o tsv)