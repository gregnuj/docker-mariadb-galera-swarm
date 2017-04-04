#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
    set -x
fi

declare command=( "docker-entrypoint.sh" $@ )

source cluster_info.sh
source galera_cnf.sh

# new cluster
if [[ $(cluster_bootstrap) -eq 1 ]]; then
    command=( ${command[@]} "--wsrep-new-cluster" )
fi

exec "${command[@]}"
