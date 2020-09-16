#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCALE_FACTOR=${SCALE_FACTOR:-100}
JOBS=${JOBS:-1}
CLIENTS=${CLIENTS:-$JOBS}

# Start database
/usr/lib/postgresql/12/bin/postgres -D /var/lib/postgresql/12/main -c config_file=/etc/postgresql/12/main/postgresql.conf &

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

retry 10 pg_isready -h localhost -d "${DB_NAME}" -U postgres

psql --command "CREATE USER ${DB_USER} WITH SUPERUSER PASSWORD '${DB_PASSWORD}';"
psql --command "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER} LC_COLLATE 'C.UTF-8' LC_CTYPE 'C.UTF-8'"

pgbench -i "${DB_NAME}" -s ${SCALE_FACTOR} ${JOB_NAME}

sleep infinity
