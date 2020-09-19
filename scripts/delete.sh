#!/usr/bin/env bash
set -eux

echo "Deleting azure resource group"

az group delete -g "${GROUP}" --no-wait -y
