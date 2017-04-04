#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [ ! -z "$DEBUG" -a "$DEBUG" != 0 -a "${DEBUG^^}" != "FALSE" ]; then
  set -x
fi

source mysql_info.sh

usage(){
    echo "($basename $0) - Approximation of useradd for maraidb/mysql"
    echo "Usage: mysql_local.sh [options] LOGIN"
    echo ""
    echo "Options:"
    echo "  -h, --help                    display this help message and exit"
    echo "  -p, --password PASSWORD       password"
    echo "  -u, --user NAME               user name"
}

croak(){
    echo "($basename $0): $1" >&2
    echo "Try \`($basename $0) --help' for more information." >&2
    exit 1 
}

while [[ -n "$@" ]]; do
    case "$1" in
        -h|--help)
            shift
            usage 
            exit
            ;;
        -p|--password)
            shift
            MYSQL_QUERY_PASSWORD="$1"
            ;;
        -u|--user)
            shift
            MYSQL_QUERY_USER="$(mysql_user $1)"
            ;;
    esac
    shift
done

# Check 

if [[ -z "$MYSQL_QUERY_USER" ]]; then
    MYSQL_QUERY_USER="root"
fi

if [[ -z "$MYSQL_QUERY_PASSWORD" ]]; then
    MYSQL_QUERY_PASSWORD="$(mysql_password root)"
fi
    
mysql=( mysql --protocol=socket --socket=/var/run/mysqld/mysqld.sock -hlocalhost)
mysql+=( -u"${MYSQL_QUERY_USER}" )
mysql+=( -p"${MYSQL_QUERY_PASSWORD}" )

exec "${mysql[@]}"
