#!/usr/bin/env bash
set -o nounset
set -o pipefail

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

PGDATABASE="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 10 | head -n 1)"
PGUSER="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 10 | head -n 1)"
PGPASSWORD="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 10 | head -n 1)"
PGHOST="postgresql.default.svc.cluster.local"

# errexit should be after the above, since they return non-zero exit codes (???)
set -o errexit

echo "Defining cleanup function"
function cleanup() {
    rm pg-config.yaml > /dev/null || true
}

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

echo "Setting cleanup trap"
trap cleanup EXIT

echo "Checking for secret"
OLD_SECRET="$(kubectl get secret pg-config --ignore-not-found -o yaml)"

if [[ -z "$OLD_SECRET" ]]; then
    echo "Creating secret"
    set +x
    kubectl create secret generic pg-config -o yaml --dry-run \
        --from-literal=PGDATABASE="${PGDATABASE}" \
        --from-literal=PGUSER="${PGUSER}" \
        --from-literal=PGPASSWORD="${PGPASSWORD}" \
        --from-literal=PGPASS="${PGHOST}:5432:${PGDATABASE}:${PGUSER}:${PGPASSWORD}" \
        --from-literal=PGPASSFILE="/tmp/postgres/.pgpass" > pg-config.yaml
    set -x
    kubectl apply -f pg-config.yaml
    rm pg-config.yaml || true
fi

echo "Applying postgresql manifests"
kustomize build manifests/postgresql | envsubst | kubectl apply -f -

echo "Waiting for postgresql rollout"
kubectl rollout status deploy/postgresql

echo "Applying pgbench manifests"
cat manifests/pgbench/config.yaml | envsubst > tmp.yaml
mv tmp.yaml manifests/pgbench/config.yaml
kustomize build manifests/pgbench | kubectl apply -f -

echo "Waiting for pgbench rollout"
kubectl rollout status deploy/pgbench

echo "Successfully applied all manifests"
