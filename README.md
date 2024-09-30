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

### 0. Login and Register Resource Providers

```bash
    az login
    ./scripts/register-providers.sh
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

### 6. Provision Infrastructure of Tenant 1

Now everything is in place to terraform the infrastructure for tenant 1.

```bash
    ./scripts/provision-tenant-infra.sh "tenant-1" "tenant-1"
```

### 7. Provision Infrastructure of Tenant 2

Now everything is in place to terraform the infrastructure for tenant 2.

```bash
    ./scripts/provision-tenant-infra.sh "tenant-2" "tenant-2"
```

### Test the Access Rules

The access rules can be validated by trying to modify infrastructure of `tenant-2` while impersonating `tenant-1`:

```bash
    ./scripts/provision-tenant-infra.sh "tenant-1" "tenant-2"
```

The returned error message indicates that reading the Terraform state file failed, which is expected behaviour.