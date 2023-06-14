#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -o errexit 

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

echo "querying imds for data"

METADATA="$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-06-01")"

echo "data found: $METADATA"

echo $METADATA | jq .

SUBSCRIPTION="$(echo $METADATA | jq -r .compute.subscriptionId)"
GROUP="$(echo $METADATA | jq -r .compute.resourceGroupName)"
IDENTITY="/subscriptions/${SUBSCRIPTION}/resourceGroups/${GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/nodesig-agent-identity"

# echo "Subscription ID: ${SUBSCRIPTION}"
echo "resourceGroupName: ${GROUP}"
echo "Managed identity: ${IDENTITY}"

echo "logging into azure"

az login --identity -u "${IDENTITY}

# az login --identity --allow-no-subscriptions -u "${IDENTITY}"

# az login --service-principal --username "${CLIENT_APP}" --password "${CLIENT_PASSWORD}" --tenant "${TENANT_ID}"

echo "successfully logged in!"
