#!/usr/bin/env bash
set -x

# cluster
export GROUP="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1)"
export LOCATION="southcentralus"
export CACHING="None"
export NODE_VM_SIZE="Standard_D4s_v3"
export NODE_OSDISK_TYPE="Managed"
export NODE_OSDISK_SIZE="2048"

# pgbench
export JOB_NAME="bench1"
export JOBS="2"
export CLIENTS="4"
export DURATION="120"
export SCALE_FACTOR="120"
export DATA_DIR="/var/lib/postgresql/12/main"
