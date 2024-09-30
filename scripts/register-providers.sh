#!/bin/bash

set -euxo pipefail

az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network