#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -x

export PATH=$PATH:${HOME}/bin

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"
TOTAL_SECONDS=600

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

# errexit should be after the above, since they return non-zero exit codes (???)
set -o errexit

echo "Applying stressng manifests"
# kubectl create -f manifests/stressng/stressng.yaml
kustomize build manifests/stressng | kubectl apply -f -

echo "Waiting for stressng rollout"
retry 3 kubectl rollout status deploy/stressng

kubectl describe deploy stressng

# no idea if this works
# adapted from something I know does work:
# https://github.com/Azure/AgentBaker/pull/2535/files#diff-1f36afed0398c5c4a7d571e9b4f5ad52236fbf7dbb33cf44f8e2bf17a56f23feR10
# timeout expected to return 124

end_time=$(date -ud "$TOTAL_SECONDS seconds" +%s)
start_time=$(date -u +%s)

while [ $(date -u +%s) -le $end_time ]
do
if kubectl get nodes | grep -q "NotReady"; then
        not_ready=true
fi

current_time=$(date -u +%s)
elapsed_time=$((current_time - start_time))
percent_complete=$((elapsed_time * 100 / TOTAL_SECONDS))
echo -ne "Elapsed time: $elapsed_time seconds / $TOTAL_SECONDS seconds ($percent_complete%)\033[0K\r"
sleep 1
done

kubectl describe node

events=$(kubectl get events --all-namespaces)

kubelet_count=$(echo "$events" | grep -c "KubeletIsDown")
containerd_count=$(echo "$events" | grep -c "ContainerdIsDown")
unknown_count=$(echo "$events" | grep -c "Unknown")

echo "kubelet.service went down $kubelet_count times"
echo "containerd.service went down $containerd_count times"
echo "essential k8s services went unknown $unknown_count times" 
[ "$not_ready" = true ] && echo "Some nodes went not ready" || echo "All nodes were ready"
