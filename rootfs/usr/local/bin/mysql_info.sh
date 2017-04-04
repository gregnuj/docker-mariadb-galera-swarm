#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
  set -x
fi

source docker_info.sh

# Defaults to /var/lib/mysql
function mysql_dir(){
    DATADIR="${DATADIR:="/var/lib/mysql"}"
    echo "${DATADIR}"
}

function mysql_auth(){
    USER="$(mysql_user $1)"
    PASSWORD="$(mysql_password $1)"
    echo "$USER:$PASSWORD"
}

function mysql_user(){
    if [[ -n "$1" ]]; then
        USER="$1"
    else
        USER=${MYSQL_USER:="root"}
    fi
    echo "$USER"
}

function mysql_password(){
    USER="$(mysql_user $1)"
    if [[ $USER == "root" ]]; then
        PASSWORD="${MYSQL_ROOT_PASSWORD:="${MYSQL_ROOT_PASSWORD_FILE}"}"
    elif [[ $USER == "${MYSQL_USER}" ]]; then
        PASSWORD="${MYSQL_PASSWORD:="${MYSQL_PASSWORD_FILE}"}"
    fi

    if [[ -r "$PASSWORD" ]]; then
        PASSWORD="$(cat "$PASSWORD")"        
    elif [[ -z "$PASSWORD" && -r "/var/run/secrets/$USER" ]]; then
        PASSWORD="$(cat "/var/run/secrets/${USER}")"
    elif [[ -z "$PASSWORD" ]]; then
        PASSWORD="$(echo "$USER:$MYSQL_ROOT_PASSWORD" | sha256sum | awk '{print $1}')"
    fi

    echo "${PASSWORD}"
}


function mysql_admin(){
    MYSQL_ADMIN=( mysql --protocol=socket --socket=/var/run/mysqld/mysqld.sock -hlocalhost )
    MYSQL_ADMIN+=( -u"$(mysql_user root)" )
    MYSQL_ADMIN+=( -p"$(mysql_password root)" )
    echo "${MYSQL_ADMIN[@]}"
}

function main(){
    case "$1" in
        -a|--auth)
            echo "$(mysql_auth $2)"
            ;;
        -d|--dir)
            echo "$(mysql_dir)"
            ;;
        -p|--password)
            echo "$(mysql_password $2)"
            ;;
        -u|--user)
            echo "$(mysql_user $2)"
            ;;
    esac
}

main "$@"
