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

echo "Subscription ID: $(echo $METADATA | jq .compute.subscriptionId)"
echo "resourceGroupName: $(echo $METADATA | jq .compute.resourceGroupName)"

echo "Managed identity: /subscriptions/$(echo $METADATA | jq -r .compute.subscriptionId)/resourceGroups/$(echo $METADATA | jq -r .compute.resourceGroupName)/Microsoft.ManagedIdentity/userAssignedIdentities/$(echo $METADATA | jq -r .compute.resourceGroupName)-identity"