#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <STORAGE_ACCOUNT_NAME> <SERVICE_PRINCIPAL_NAME> <TENANT_ID>" 
    exit 1
fi

if [ "$3" != "tenant-1" ] && [ "$3" != "tenant-2" ]; then
    echo "Error: TENANT_ID must be either 'tenant-1' or 'tenant-2'"
    exit 1
fi

set -euxo pipefail

export STORAGE_ACCOUNT_NAME=$1
storage_account_id=$(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group rg-tfstate --query id -o tsv)
storage_container_scope="$storage_account_id/blobServices/default/containers/tfstate"

sp_name=$2
export ARM_CLIENT_SECRET=$(az ad sp create-for-rbac --name $sp_name --query "password" -o tsv)
export ARM_CLIENT_ID=$(az ad sp list --display-name $sp_name --query "[].appId" -o tsv)
export ARM_TENANT_ID=$(az ad sp list --display-name $sp_name --query "[].appOwnerOrganizationId" -o tsv)
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
sp_id=$(az ad sp list --display-name $sp_name --query "[].id" -o tsv)

export TENANT_ID=$3
tenant_folder_condition=$(envsubst < ./templates/abac-conditions.template)
az role assignment create --assignee "$sp_id" --role "Storage Blob Data Contributor" --scope "$storage_container_scope" --description "Restrict access to blobs" --condition "$tenant_folder_condition" --condition-version "2.0"

rg_name="rg-$TENANT_ID"
az group create --name $rg_name --location westeurope
az role assignment create --assignee "$sp_id" --role "Contributor" --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/$rg_name"

envsubst < ./templates/sp-credentials.template > ./sp-credentials-$TENANT_ID.sh
