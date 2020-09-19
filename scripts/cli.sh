#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -o errexit 

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

set -x

sudo apt install -y python3 python3-pip python3-virtualenv socat
git clone https://github.com/Azure/azure-cli-extensions
git clone https://github.com/Azure/azure-cli

pushd azure-cli-extensions

python3 -m virtualenv --python=/usr/bin/python3 venv

set +o nounset
source venv/bin/activate
set -o nounset

pip install azdev

azdev setup -c ../azure-cli -r . -e aks-preview

az aks nodepool add -h
