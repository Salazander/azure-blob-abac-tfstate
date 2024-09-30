#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <STORAGE_ACCOUNT_NAME>" 
    exit 1
fi

set -euxo pipefail

az group create --name rg-tfstate --location westeurope
storage_account_name=$1
az storage account create --name $storage_account_name --resource-group rg-tfstate --location westeurope --sku Standard_LRS
az storage container create --name tfstate --account-name $storage_account_name --auth-mode login
