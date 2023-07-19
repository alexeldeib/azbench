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
# kubectl create -f manifests/stressng/stressng.yaml
kustomize build manifests/stressng | kubectl apply -f -

echo "Waiting for stressng rollout"
retry 3 kubectl rollout status deploy/stressng

kubectl describe deploy stressng

echo "Finished stressng deployment"

set +o errexit

sleep 900

echo "1) Describing Node..."
kubectl describe node

echo "2) Getting Events..."
kubectl get events

ret=$(kubectl get events | grep -c 'NodeNotReady')
kubelet_count=$(kubectl get events | grep -c "KubeletIsDown")
containerd_count=$(kubectl get events | grep -c "ContainerdIsDown")
unknown_count=$(kubectl get events | grep -c "Unknown")

echo "3) Printing Results..."
echo "--------------------------------------------------------"
echo "*** kubelet.service went down $kubelet_count times"
echo "*** containerd.service went down $containerd_count times"
echo "*** essential k8s services went unknown $unknown_count times" 
echo "*** node went NotReady due to stress $((ret-1)) times"
echo "--------------------------------------------------------"

if [ "${ret}" -gt 1 ]; then
  echo "some nodes went not ready during run"
  exit ${1}
fi

echo "Successfully ran stressng without failures"

