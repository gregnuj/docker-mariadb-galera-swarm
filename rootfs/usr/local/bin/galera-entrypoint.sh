#!/bin/bash
#

set -eo pipefail
shopt -s nullglob

source "cluster_common.sh"

declare WANTHELP=$(echo "$@" | grep '\(-?\|--help\|--print-defaults\|-V\|--version\)')

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ -n "$DEBUG" ]]; then
    set -x
fi

# if command starts with an option, prepend mysqld
if [[ "${1:0:1}" = '-' ]]; then
    set -- mysqld "$@"
fi

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
    set -- mysqld "$@"
fi

# command is not mysqld 
if [[ $1 != 'mysqld' ]]; then
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

# Configure mysql if needed
if [[ ! -d "$(mysql_datadir)/mysql" ]]; then
    MYSQLD_INIT=${MYSQLD_INIT:=1}
fi
if [[ ! -z "${MYSQLD_INIT}" ]]; then
    source "mysql_init.sh"
fi

# Configure galera unless config exists
if [[ ! -f "$(cluster_cnf)" ]]; then
    CLUSTER_INIT=${CLUSTER_INIT:=1}
fi
if [[ ! -z "${CLUSTER_INIT}" ]]; then
    source "cluster_init.sh"
fi

# Attempt recovery if possible
command=( "$@" )
if [[ "$(cluster_primary)" == "$(node_address)" ]]; then
    command+=( " --wsrep-new-cluster" )
fi

exec "${command[@]}"
