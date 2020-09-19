#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -x

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

echo "Removing old manifests"

kustomize build manifests | kubectl delete -f -
kustomize build manifests/nsenter | kubectl delete -f -
kubectl delete secret pg-config
