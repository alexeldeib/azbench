#!/usr/bin/env bash
set -o errexit
set -o pipefail

SCALE_FACTOR=${SCALE_FACTOR:-100}
DURATION=${DURATION:-60}
JOBS=${JOBS:-1}
CLIENTS=${CLIENTS:-$JOBS}

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
retry() {
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

retry 10 pg_isready -h $PGHOST -d $PGDATABASE -U $PGUSER

pgbench -h $PGHOST -d "${PGDATABASE}" -U $PGUSER --client=${CLIENTS} --jobs=${JOBS} --time=${DURATION} -s ${SCALE_FACTOR} ${JOB_NAME}

sleep infinity
