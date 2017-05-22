#!/bin/bash
#

set -eo pipefail
shopt -s nullglob

source "cluster_common.sh"

declare WANTHELP=$(echo "$@" | grep '\(-?\|--help\|--print-defaults\|-V\|--version\)')
declare -a cmd=( "$*" )

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ -n "$DEBUG" ]]; then
    set -x
fi

# if command starts with an option, prepend mysqld
if [[ "${1:0:1}" = '-' ]]; then
    set -- mysqld "$@"
fi

# command is not mysqld 
if [[ $1 != 'mysqld' && $1 != 'mysqld_safe' ]]; then
    exec "$@"
fi

# command has help param
if [[ ! -z "$WANTHELP" ]]; then
    exec "$@"
fi

# allow the container to be started with `--user`
if [[ "$(id -u)" = '0' ]]; then
    exec gosu mysql "$BASH_SOURCE" "$@"
fi

# Set env MYSQLD_INIT to trigger setup 
if [[ ! -d "$(mysql_datadir)/mysql" ]]; then
    MYSQLD_INIT=${MYSQLD_INIT:=1}
fi

# Configure database if MYSQLD_INIT is set
if [[ ! -z "${MYSQLD_INIT}" ]]; then
    source "mysql_init.sh"
fi

# Set env to trigger creation of galera.cnf
if [[ ! -f "$(cluster_cnf)" ]]; then
    CLUSTER_INIT=${CLUSTER_INIT:=1}
fi

# create galera.cnf
if [[ ! -z "${CLUSTER_INIT}" ]]; then
    source "cluster_init.sh"
fi

# Attempt recovery if possible
if [[ -f "$(grastate_dat)" ]]; then
    mysqld ${cmd[@]:1} --wsrep-recover
elif [[ ! -z "$(is_cluster_primary)" ]]; then
    galera_new_cluster 
else
    # 2 minute sleep if no pc found
    pc="$(nc -z -w 120 "$(service_name)" -p 4567)"
fi

exec ${cmd[*]}
