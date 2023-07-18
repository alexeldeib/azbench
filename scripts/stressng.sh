#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -x

export PATH=$PATH:${HOME}/bin

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"
TOTAL_SECONDS=10

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
# set -o errexit

echo "Applying stressng manifests"
kubectl create -f manifests/stressng/stressng.yaml
# kustomize build manifests/stressng | kubectl apply -f -

sleep 10
echo "Waiting for stressng rollout"
retry 3 kubectl rollout status deploy/stressng

kubectl describe deploy stressng

echo "Finished deployment"

touch logs.txt
# sleep ${TOTAL_SECONDS}
timeout ${TOTAL_SECONDS}s kubectl get node -w > logs.txt

events=$(kubectl describe node --all-namespaces)

kubectl describe node

notready_count=$(grep -c 'NotReady' logs.txt)
kubelet_count=$(echo "$events" | grep -c "KubeletIsDown")
containerd_count=$(echo "$events" | grep -c "ContainerdIsDown")
unknown_count=$(echo "$events" | grep -c "Unknown")

echo "--------------------------------------------------------"
echo "kubelet.service went down $kubelet_count times"
echo "containerd.service went down $containerd_count times"
echo "essential k8s services went unknown $unknown_count times" 
echo "--------------------------------------------------------"
echo "node went 'NotReady' $notready_count times"
echo "--------------------------------------------------------"
echo "Successfully ran"
