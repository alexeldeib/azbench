#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -o errexit 

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

set -x

az keyvault secret download --vault-name aks-dataplane-test -n gcs -f cert.pfx
openssl rsa -in cert.pfx -out gcskey.pem
openssl x509 -in cert.pfx -out gcscert.pem
rm cert.pfx

echo "Starting metrics container"

docker run \
    -d \
    -v $(pwd)/gcscert.pem:/etc/certs/gcscert.pem \
    -v $(pwd)/gcskey.pem:/etc/certs/gcskey.pem \
    --rm \
    -p 8125:8125/udp \
    --name ${GROUP} \
    alexeldeib/metrics:latest \
    -StatsdPort 8125 \
    -Logger Console \
    -FrontEndUrl https://global.int.microsoftmetrics.com \
    -CertFile /etc/certs/gcscert.pem \
    -PrivateKeyFile /etc/certs/gcskey.pem \
    -Input statsd_udp
