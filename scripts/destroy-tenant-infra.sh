#!/bin/bash

if [ "$1" != "tenant-1" ] && [ "$1" != "tenant-2" ]; then
    echo "Usage: $0 <LOGIN_AS_TENANT_ID> <MODIFY_INFRA_OF_TENANT_ID>"
    echo "Error: LOGIN_AS_TENANT_ID must be either 'tenant-1' or 'tenant-2'"
    exit 1
fi

if [ "$2" != "tenant-1" ] && [ "$2" != "tenant-2" ]; then
    echo "Usage: $0 <LOGIN_AS_TENANT_ID> <MODIFY_INFRA_OF_TENANT_ID>"
    echo "Error: MODIFY_INFRA_OF_TENANT_ID must be either 'tenant-1' or 'tenant-2'"
    exit 1
fi

set -e

source ./sp-credentials-$1.sh
az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
cd terraform/$2
terraform init -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" -reconfigure
terraform destroy