# azure-blob-abac-tfstate

This repository provides a guide on securely utilizing a single Azure Blob Container as the state backend storage for a multi-tenant solution managed by Terraform.

## Introduction

Multi-tenant cloud solutions sometimes require tenant-specific resources to be provisioned.
Managing multiple `tfstate` files in a shared Azure Blob Container requires careful design of the access policies.
[ABAC](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-auth-abac)-rules can be leveraged to ensure that Terraform only gets access to the state files of the tenant that requires infrastructural changes.

## Before you start

Reopen this repository inside of the provided [`devcontainer`](https://code.visualstudio.com/docs/devcontainers/containers).
All dependencies will come pre-installed.
You will need an Azure Subscription to perform the steps mentioned below.

## Step-By-Step Guide

The following steps will provision the following architecture:

![Architecture Diagram](diagrams/architecture.png)

### 0. Login

```bash
    az login
```

### 1.+2.+3. Create the Storage Account

Since storage account names must be unique, adapt the placeholder with an available name.

```bash
    ./scripts/create-storage-account.sh "<UNIQUE_STORAGE_ACCOUNT_NAME>"
```

### 4. Onboard Tenant 1

Since service principal names must be unique, adapt the placeholder with an available name.

```bash
    ./scripts/onboard-tenant.sh "<UNIQUE_SP_NAME_1>" "tenant-1"
```

### 5. Onboard Tenant 2

Since service principal names must be unique, adapt the placeholder with an available name.

```bash
    ./scripts/onboard-tenant.sh "<UNIQUE_SP_NAME_2>" "tenant-2"
```

