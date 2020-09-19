#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -o errexit 

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
function retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1

    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            echo "Attempt $attempt_num failed and there are no more attempts left!"
            return 1
        else
            echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
            sleep $(( attempt_num++ ))
        fi
    done
}

retry 200 kubectl logs --tail 12 "$(kubectl get pod -l app=pgbench -o jsonpath="{.items[0].metadata.name}")"

echo "Checking for completion"

function get_logs() {
    echo "$(kubectl logs --tail 12 "$(kubectl get pod -l app=pgbench -o jsonpath="{.items[0].metadata.name}")")"
}

function grep_logs() {
    echo "$(get_logs)" | grep "TESTING COMPLETE"
}

max_attempts=200
attempt_num=1
until [[ ! -z "$(grep_logs)" ]]; do 
    if (( attempt_num == max_attempts )); then
        echo "Attempt $attempt_num failed and there are no more attempts left!"
        return 1
    else
        echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
        sleep $(( attempt_num++ ))
    fi
done

set -x

echo "Fetching logs for data parsing"
get_logs
get_logs > logs.out

echo "Calculating metrics"
SCALE="$(cat logs.out | sed '1q;d' - | cut -d ' ' -f3)"
CLIENTS="$(cat logs.out | sed '3q;d' - | cut -d ' ' -f4)"
THREADS="$(cat logs.out | sed '4q;d' - | cut -d ' ' -f4)"
DURATION="$(cat logs.out | sed '5q;d' - | cut -d ' ' -f2)"
LATENCY_AVG="$(cat logs.out | sed '7q;d' - | cut -d ' ' -f4)"
TPS_WITH_CONN="$(cat logs.out | sed '8q;d' - | cut -d ' ' -f3)"
TPS_WITHOUT_CONN="$(cat logs.out | sed '9q;d' - | cut -d ' ' -f3)"

export CACHING="None"
export NODE_VM_SIZE="Standard_D4s_v3"
export NODE_OSDISK_TYPE="Managed"
export NODE_OSDISK_SIZE="2048"

DIMENSIONS="\"Dims\": {
        \"scale\": \"${SCALE}\",
        \"threads\": \"${THREADS}\",
        \"clients\": \"${CLIENTS}\",
        \"duration\": \"${DURATION}\",
        \"vmsize\": \"${NODE_VM_SIZE}\",
        \"osdisktype\": \"${NODE_OSDISK_TYPE}\",
        \"osdisksize\": \"${NODE_OSDISK_SIZE}\",
        \"workloaddisk\": \"os\"
    }"

echo "Emitting pgbench_latency"

PAYLOAD="{
    \"Account\": \"aks-data-plane\",
    \"Namespace\":\"BlackboxMonitoring\",
    \"Metric\":\"pgbench_latency\",
    ${DIMENSIONS}
}:${LATENCY_AVG}|f"

echo "${PAYLOAD}" | tr -d ' \n' | socat -t 1 - UDP-SENDTO:127.0.0.1:8125

echo "Emitting pgbench_tps_with_conn"

PAYLOAD="{
    \"Account\": \"aks-data-plane\",
    \"Namespace\":\"BlackboxMonitoring\",
    \"Metric\":\"pgbench_tps_with_conn\",
    ${DIMENSIONS}
}:${TPS_WITH_CONN}|f"

echo "${PAYLOAD}" | tr -d ' \n' | socat -t 1 - UDP-SENDTO:127.0.0.1:8125

echo "Emitting pgbench_tps_without_conn"

PAYLOAD="{
    \"Account\": \"aks-data-plane\",
    \"Namespace\":\"BlackboxMonitoring\",
    \"Metric\":\"pgbench_tps_without_conn\",
    ${DIMENSIONS}
}:${TPS_WITHOUT_CONN}|f"

echo "${PAYLOAD}" | tr -d ' \n' | socat -t 1 - UDP-SENDTO:127.0.0.1:8125

