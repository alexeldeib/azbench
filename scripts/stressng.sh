#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -x

export PATH=$PATH:${HOME}/bin

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"
TOTAL_SECONDS=300

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
kustomize build manifests/stressng | kubectl apply -f -

echo "Waiting for stressng rollout"
retry 3 kubectl rollout status deploy/stressng

kubectl describe deploy stressng

# no idea if this works
# adapted from something I know does work:
# https://github.com/Azure/AgentBaker/pull/2535/files#diff-1f36afed0398c5c4a7d571e9b4f5ad52236fbf7dbb33cf44f8e2bf17a56f23feR10
# timeout expected to return 124
set +o errexit

timeout ${TOTAL_SECONDS}s kubectl get node -w | tee logs

# might need to change timeout
tail -n 100 logs
grep 'NotReady' logs
ret=$?
if [ "${ret}" == "1" ]; then

  echo "Displaying results..."

  echo "Describing Node..."
  kubectl describe node

  echo "Getting Events..."
  kubectl get events

  echo "some nodes went not ready during run"
  exit ${ret}
fi

echo "Displaying results..."

echo "Describing Node..."
kubectl describe node

echo "Getting Events..."
kubectl get events

echo "Successfully ran stressng without failures"
