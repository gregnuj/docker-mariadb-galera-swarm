#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
    set -x
fi

source docker_info.sh

declare SERVICE_NAME="${SERVICE_NAME:="$(service_name)"}"
declare MYSQL_DATABASE="${MYSQL_DATABASE:="${SERVICE_NAME%-*}"}"
declare MYSQL_USER="${MYSQL_USER:="${MYSQL_DATABASE}"}"

# Read optional secrets from files
if [ -z $MYSQL_PASSWORD ] && [ -f $MYSQL_PASSWORD_FILE ]; then
	MYSQL_PASSWORD=$MYSQL_PASSWORD_FILE
fi

if [ -z $MYSQL_PASSWORD ]; then
    mysql_useradd.sh -U "$MYSQL_USER" -p "$MYSQL_PASSWORD"
else
    mysql_useradd.sh -U "$MYSQL_USER" 
fi


echo "Created user $MYSQL_USER"

