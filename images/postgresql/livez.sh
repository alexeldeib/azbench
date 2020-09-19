#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

pg_isready -h localhost -d "${DB_NAME}" -U postgres
