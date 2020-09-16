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

echo "Setting cleanup trap"

trap cleanup EXIT

echo "Creating secret"

SECRET_CONTENT=""
SECRET_CONTENT="${SECRET_CONTENT}PGDATABASE=${PGDATABASE}\n"
SECRET_CONTENT="${SECRET_CONTENT}PGUSER=${PGUSER}\n"
SECRET_CONTENT="${SECRET_CONTENT}PGPASSWORD=${PGPASSWORD}\n"
SECRET_CONTENT="${SECRET_CONTENT}PGPASS=${PGHOST}:5432:${PGDATABASE}:${PGUSER}:${PGPASSWORD}\n"

echo -e "$SECRET_CONTENT" > manifests/pg-config

# kubectl create secret generic pg-config -o yaml --dry-run=client \
    # --from-literal=PGDATABASE="${PGDATABASE}" \
    # --from-literal=PGUSER="${PGUSER}" \
    # --from-literal=PGPASSWORD="${PGPASSWORD}" \
    # --from-literal=PGPASS="${PGHOST}:5432:${PGDATABASE}:${PGUSER}:${PGPASSWORD}" > pg-config.yaml

# kubectl apply -f pg-config.yaml
rm pg-config.yaml || true

echo "Applying manifests"

kustomize build manifests | kubectl apply -f -
