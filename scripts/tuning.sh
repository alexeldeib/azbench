#!/usr/bin/env bash
set -o pipefail
set -o nounset
set -o errexit
set -x

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

export PATH=$PATH:${HOME}/bin

function get_restarts() {
    echo "$(kubectl get pod -l app=nsenter -o jsonpath="{.items[*].status.containerStatuses[0].restartCount}")"
}

function get_pod_phase() {
    echo "$(kubectl get pod -l app=nsenter -o jsonpath="{.items[*].status.phase}")"
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
    POD_COUNT="$(kubectl get pod -l app=nsenter -o jsonpath="{.items[*].metadata.name}" | wc -w)"
    ALL_RESTARTED="false"
    while [[ ! "${ALL_RESTARTED}" == "true" ]]; do
        RESTARTS="$(get_restarts)"
        COUNT=0
        for IS_RESTARTED in ${RESTARTS}; do
            if [[ "${IS_RESTARTED}" == "1" ]]; then
                COUNT=$((COUNT + 1))
            fi
        done
        if [[ "${COUNT}" == "${POD_COUNT}" ]]; then
            echo "All pods ready after one restart"
            ALL_RESTARTED="true"
        else
            echo "Found ${COUNT} pods, need ${POD_COUNT} to restart"        
        fi
    done

    echo "Waiting for all pods to be ready after restart"
    ALL_POD_READY="false"
    while [[ "${ALL_POD_READY}" != "true" ]]; do
        READY="$(get_pod_phase)"
        READY_COUNT=0
        for IS_READY in ${READY}; do
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
    ALL_NODE_READY="false"
    while [[ "${ALL_NODE_READY}" != "true" ]]; do
        READY="$(get_node_status)"
        READY_COUNT=0
        for IS_READY in ${READY}; do
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
