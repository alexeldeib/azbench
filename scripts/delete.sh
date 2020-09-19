#!/usr/bin/env bash
set -eux

echo "Deleting azure resource group"

docker stop "${GROUP}"
az group delete -g "${GROUP}" --no-wait -y
