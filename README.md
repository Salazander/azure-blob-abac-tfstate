# azure-blob-abac-tfstate

This repository offers guidance on securely using a single Azure Blob Container as the state backend storage for a multi-tenant solution managed by Terraform.
> Note: The words tenant and customer are used interchangeably in this document. They refer to the end-user of the software solution.

## Introduction

Multi-tenant software solutions need to ensure that each onboarded customer's data is kept private unless sharing is requested explictly.
Data separation can happen at a logical and/or physical level.
When strict physical data separation is required, dedicated cloud resources need to be provisioned.
Furthermore, some tenants might opt into advanced features that require additional cloud services.

The Terraform configuration defines the desired state of each tenant's infrastructure.
To cater for the individuality of each customer's cloud resources, it is advisable to split the Terraform configuration accordingly.
In most cases, splitting the system architecture will lead to multiple `tfstate` files. 
In this example, the cloud resources of each tenant are kept in distinct state files.

Managing multiple `tfstate` files in a shared Azure Blob Container requires careful design of the access policies.
[ABAC](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-auth-abac)-rules can be leveraged to ensure that Terraform only gets access to the state files of the tenant that requires infrastructural changes.

The next sections will illustrate how to leverage Service Principals and ABAC-rules to restrict Terraform to operate on specific state files and resource groups only.

## Before you start

Reopen this repository inside of the provided [`devcontainer`](https://code.visualstudio.com/docs/devcontainers/containers).
All dependencies will come pre-installed.
You will need an Azure Subscription to perform the steps mentioned below.

## Step-By-Step Guide

The following steps will provision the following architecture:

![Architecture Diagram](diagrams/architecture.png)

### 0. Login and Register Resource Providers

```bash
az login
./scripts/register-providers.sh
```

### 1.+2.+3. Create the Storage Account

Since storage account names must be unique, replace the placeholder with an available name.

```bash
./scripts/create-storage-account.sh "<UNIQUE_STORAGE_ACCOUNT_NAME>"
```

### 4. Onboard Tenant 1

Since service principal names must be unique, replace the placeholder with an available name.

```bash
./scripts/onboard-tenant.sh "<UNIQUE_STORAGE_ACCOUNT_NAME>" "<UNIQUE_SP_NAME_1>" "tenant-1"
```

### 5. Onboard Tenant 2

Since service principal names must be unique, replace the placeholder with an available name.

```bash
./scripts/onboard-tenant.sh "<UNIQUE_STORAGE_ACCOUNT_NAME>" "<UNIQUE_SP_NAME_2>" "tenant-2"
```

### 6. Provision Infrastructure of Tenant 1

Now everything is in place to terraform the infrastructure for tenant 1.

```bash
./scripts/provision-tenant-infra.sh "tenant-1" "tenant-1"
```

### 7. Provision Infrastructure of Tenant 2

Proceed with tenant 2.

```bash
./scripts/provision-tenant-infra.sh "tenant-2" "tenant-2"
```

### Test the Access Rules

The access rules can be validated by trying to modify infrastructure of `tenant-2` while impersonating `tenant-1` (or vice versa):

```bash
./scripts/provision-tenant-infra.sh "tenant-1" "tenant-2"
./scripts/provision-tenant-infra.sh "tenant-2" "tenant-1"
```

The returned error message indicates that reading the Terraform state file failed, which is expected behaviour.

## Understand the ABAC conditions

Attribute-based access control builds on top of role-based access control.
It enables the creation of conditional role assignments.
More detailed explanations can be found [here](https://learn.microsoft.com/en-us/azure/role-based-access-control/conditions-overview).
In this sample, the service principal used by Terraform requires the `Storage Blob Data Contributor`-role to manage the state files hosted in Azure Blob Storage.
The following access conditions check whether the access to a given blob path is legitimate.

```bash
(
    (
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write'})
        AND
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action'})
        AND
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete'})
        AND
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action'})
        AND
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'} AND NOT SubOperationMatches{'Blob.List'})
    )
    OR 
    (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs:path] StringLikeIgnoreCase '$TENANT_ID/*'
    )
)
```

or put differently

```
(
    (
        1st logic expression: Is the operation always allowed?
    )
    OR
    (
        2nd logic expression: Does this particular operation fulfill the access conditions?
    )
)
```

The return value of the overall logic expression (`true` or `false`) determines whether an operation will be allowed.
The first logic expression determines whether the condition defined in the second logic expression needs to be evaluated for the current action.
If not, the first logic block evaluates to `true` and the action will be allowed.
If further inspection is required, the first logic block evaluates to `false` and the second logic expression is evaluated.

In the condition defined above, the return value will be `true` if the path of the blob contains the right tenant identifier.
