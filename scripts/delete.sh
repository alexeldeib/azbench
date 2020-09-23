#!/usr/bin/env bash
set -eux

echo "Stopping metrics container"
docker stop "${GROUP}" || true

echo "Deleting azure resource group"
az group delete -g "${GROUP}" --no-wait -y
