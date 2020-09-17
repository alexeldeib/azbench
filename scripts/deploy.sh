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
    rm pg-config.yaml || true
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
    kubectl create secret generic pg-config -o yaml --dry-run=client \
        --from-literal=PGDATABASE="${PGDATABASE}" \
        --from-literal=PGUSER="${PGUSER}" \
        --from-literal=PGPASSWORD="${PGPASSWORD}" \
        --from-literal=PGPASS="${PGHOST}:5432:${PGDATABASE}:${PGUSER}:${PGPASSWORD}" > pg-config.yaml

    kubectl apply -f pg-config.yaml
    rm pg-config.yaml || true
fi

# SECRET_CONTENT=""
# SECRET_CONTENT="${SECRET_CONTENT}PGDATABASE=${PGDATABASE}\n"
# SECRET_CONTENT="${SECRET_CONTENT}PGUSER=${PGUSER}\n"
# SECRET_CONTENT="${SECRET_CONTENT}PGPASSWORD=${PGPASSWORD}\n"
# SECRET_CONTENT="${SECRET_CONTENT}PGPASS=${PGHOST}:5432:${PGDATABASE}:${PGUSER}:${PGPASSWORD}\n"

# echo -e "$SECRET_CONTENT" > manifests/postgresql/pg-config
# echo -e "$SECRET_CONTENT" > manifests/pgbench/pg-config

echo "Applying postgresql manifests"

kustomize build manifests/postgresql | kubectl apply -f -

echo "Waiting for pgbench initialization to complete"

retry 10 kubectl logs -f $(kubectl get pod -l app=postgresql -o jsonpath="{.items[0].metadata.name}") &

read -n 1 -s -r

echo "Applying pgbench manifests"

kustomize build manifests/pgbench | kubectl apply -f -

echo "Waiting for pgbench completion"

retry 10 kubectl logs -f $(kubectl get pod -l app=pgbench -o jsonpath="{.items[0].metadata.name}") &

read -n 1 -s -r
