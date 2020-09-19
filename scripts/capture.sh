#!/usr/bin/env bash
set -o nounset
set -o pipefail
set -o errexit 

BASH_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."
cd "$BASH_ROOT"

az keyvault secret download --vault-name aks-dataplane-test -n geneva-agent -e base64 -f cert.pfx
openssl pkcs12 -nocerts -nodes -passin pass: -in cert.pfx -out gcskeytmp.pem && openssl rsa -in gcskeytmp.pem -out gcskey.pem
openssl pkcs12 -nokeys -nodes -passin pass: -in cert.pfx -out gcscerttmp.pem && openssl x509 -in gcscerttmp.pem -out gcscert.pem
rm gcskeytmp.pem gcscerttmp.pem cert.pfx

echo "Starting metrics container"

docker run \
    -d \
    -v $(PWD)/gcscert.pem:/etc/certs/gcscert.pem \
    -v $(PWD)/gcskey.pem:/etc/certs/gcskey.pem \
    --rm \
    --name geneva \
    alexeldeib/metrics:latest \
    -Logger Console \
    -FrontEndUrl https://az-compute.metrics.nsatc.net \
    -CertFile /etc/certs/gcscert.pem \
    -PrivateKeyFile /etc/certs/gcskey.pem \
    -Input statsd_udp
