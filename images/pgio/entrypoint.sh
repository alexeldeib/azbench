#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

echo "Hello, PGIO!"

echo "Copying setup config file to location"
envsubst < /opt/pgio/pgio.conf > pgio.conf

echo "Current config:"
cat pgio.conf

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

echo "Running setup with current config"
bash setup.sh

echo "Executing pgio"
bash runit.sh

tree -L 2

echo "Listing output files"
echo *.out

echo "Compressiong output files to pgio-out.tar"
tar -cf pgio-out.tar *.out

echo "Serving up output archive"
wormhole send pgio-out.tar

sleep infinity
