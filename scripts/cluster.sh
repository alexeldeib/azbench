#!/usr/bin/env bash
set -o pipefail
set -o nounset
set -x

NEWGRP="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1)"
export GROUP="${GROUP:=$NEWGRP}"
export LOCATION="southcentralus"
export CACHING="${CACHING:-}"
export ACTION="${ACTION:-}"

set -o errexit # has to be after cat /dev/urandom piece

set +o nounset
source azure-cli-extensions/venv/bin/activate
set -o nounset

echo "Creating resource group"

az group create -g "${GROUP}" -l "${LOCATION}" --tags "azbench=true"

# echo "Creating identity"
# az identity create -g "${GROUP}" --name "${GROUP}-identity"

# SUBSCRIPTION="$(az account show | jq -r .id)"
# IDENTITY="/subscriptions/${SUBSCRIPTION}/resourceGroups/${GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${GROUP}-identity"

echo "Creating AKS cluster"

az aks create -g "${GROUP}" \
    -n "${GROUP}" \
    -l "${LOCATION}" \
    -c 3 \
    -k 1.17.7 \
    --service-principal "${CLIENT_APP}" \
    --client-secret "${CLIENT_PASSWORD}" \
    --enable-node-public-ip \
    --load-balancer-sku standard \
    --network-plugin azure \
    --vm-set-type VirtualMachineScaleSets \
    --node-osdisk-type=Ephemeral \
    --node-vm-size Standard_D4s_v3 \
    --node-osdisk-size 100 \
    --generate-ssh-keys > cluster.json
    # --assign-identity "${IDENTITY}" \

echo "Creating user nodepool"

az aks nodepool add -g "${GROUP}" \
    --cluster-name "${GROUP}" \
    -n agentpool1 \
    -k 1.17.7 \
    -c 3 \
    --enable-node-public-ip \
    --mode User \
    --node-vm-size "${NODE_VM_SIZE}" \
    --node-osdisk-type="${NODE_OSDISK_TYPE}" \
    --node-osdisk-size "${NODE_OSDISK_SIZE}" > nodepool.json

echo "Fetching kubeconfig"

az aks get-credentials -g "${GROUP}" -n "${GROUP}"

echo "Checking if we need to set caching mode..."

if [[ ! -z "${CACHING}" ]]; then
    echo "Caching mode: '${CACHING}', updating all VMSS instances"

    SUBSCRIPTION="$(az account show | jq -r .id)"
    MC_GROUP="MC_${GROUP}_${GROUP}_${LOCATION}"
    VMSS="$(az vmss list -g ${MC_GROUP} --query "[?contains(name, 'agentpool1')].name | [0]" | tr -d '"')"
    URI="/subscriptions/${SUBSCRIPTION}/resourceGroups/${MC_GROUP}/providers/Microsoft.Compute/virtualMachineScaleSets/${VMSS}?api-version=2020-06-01"    

    # patch vmss os disk caching, `az vmss update` does not work.
    az rest --method patch --uri "${URI}" --body "$(cat scripts/patch.json | envsubst)"
    
    # bash loop to convert json to space separated list
    az vmss list-instances -g "${MC_GROUP}" -n "${VMSS}" --query '[].instanceId | [*]' > instances.json
    
    INSTANCES=""
    while IFS=$'\n' read i; do
        INSTANCE="$(echo "${i}" | tr -d '"')"
        echo "Adding instance '${INSTANCE}' to list of instances to set Caching mode"
        INSTANCES+="${INSTANCE} "
        echo "instances: ${INSTANCES}"
    done < <(jq -c '.[]' instances.json)

    echo "Setting storageProfile.osDisk.caching='${CACHING}' for instances: '$INSTANCES'"
    az vmss update-instances -g "${MC_GROUP}" -n "${VMSS}" --instance-ids "*"
else
    echo "Caching mode not set, will default to ReadWrite on managed OS disk, ReadOnly (?) for ephemeral."
fi

echo "Successfully provisioned workload cluster"

function get_restarts() {
    echo "$(kubectl get pod -o jsonpath="{.items[*].status.containerStatuses[0].restartCount}")"
}

function get_pod_phase() {
    echo "$(kubectl get pod -o jsonpath="{.items[*].status.phase}")"
}

function get_node_status() {
    echo "$(kubectl get node -o jsonpath="{.items[*].status.conditions[?(.reason=='KubeletReady')].status}")"
}

echo "Checking if we should apply tuning"

if [[ -n "${ACTION}" ]]; then
    echo "Applying tuning manifests"
    kustomize build manifests/nsenter | envsubst | kubectl apply -f - 

    echo "Waiting for rollout"
    kubectl rollout status daemonset/nsenter

    echo "Waiting for all pods to have 1 reboot to ensure tuning applied"
    POD_COUNT="$(kubectl get pod -o jsonpath="{.items[*].metadata.name}" | wc -w)"
    ALL_RESTARTED=""
    while [[ "${ALL_RESTARTED}" -ne "true" ]]; do
        RESTARTS="$(get_restarts)"
        if [[ "${RESTARTS}" == "${POD_COUNT}" ]]; then
            echo "All pods restarted once"
            ALL_RESTARTED="true"
        else
            echo "Found ${RESTARTS} pods, need ${POD_COUNT} to restart"        
        fi
    done

    echo "Waiting for all pods to be ready after restart"
    ALL_POD_READY=""
    while [[ "${ALL_POD_READY}" -ne "true" ]]; do
        READY="$(get_pod_phase)"
        READY_COUNT=0
        for IS_READY in "${READY}"; do
            if [[ "${IS_READY}" == "Running" ]]; then
                READY_COUNT=$((READY_COUNT + 1))
            fi
        done
        if [[ "${READY_COUNT}" == "${POD_COUNT}" ]]; then
            echo "All pods ready after one restart"
            ALL_POD_READY="true"
        fi
    done

    echo "Waiting for all nodes to be ready after restart"
    NODE_COUNT="$(kubectl get node -o jsonpath="{.items[*].metadata.name}" | wc -w)"
    ALL_NODE_READY=""
    while [[ "${ALL_NODE_READY}" -ne "true" ]]; do
        READY="$(get_node_status)"
        READY_COUNT=0
        for IS_READY in "${READY}"; do
            if [[ "${IS_READY}" == "True" ]]; then
                READY_COUNT=$((READY_COUNT + 1))
            fi
        done
        if [[ "${READY_COUNT}" == "${NODE_COUNT}" ]]; then
            echo "All nodes ready after one restart"
            ALL_NODE_READY="true"
        fi
    done
    echo "Successfully completed all tuning and validation"
else
    echo "No tuning required."
fi
