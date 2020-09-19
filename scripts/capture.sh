#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -o errexit 

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

az keyvault secret download --vault-name aks-dataplane-test -n geneva-agent -e base64 -f cert.pfx
openssl pkcs12 -nocerts -nodes -passin pass: -in cert.pfx -out gcskey.pem && openssl rsa -in gcskey.pem -out config/gcskey.pem
openssl pkcs12 -nokeys -nodes -passin pass: -in cert.pfx -out gcscert.pem && openssl x509 -in gcscert.pem -out config/gcscert.pem
rm gcskey.pem gcscert.pem cert.pfx

echo "Starting metrics container"

docker run \
    -d \
    -v $(PWD)/config/gcscert.pem:/etc/certs/gcscert.pem \
    -v $(PWD)/config/gcskey.pem:/etc/certs/gcskey.pem \
    --rm \
    --name geneva \
    alexeldeib/metrics:latest \
    -Logger Console \
    -FrontEndUrl https://az-compute.metrics.nsatc.net \
    -CertFile /etc/certs/gcscert.pem \
    -PrivateKeyFile /etc/certs/gcskey.pem \
    -Input statsd_udp
