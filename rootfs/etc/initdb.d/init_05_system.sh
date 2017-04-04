#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
  set -x
fi

declare GALERA_USER="${GALERA_USER:="xtrabackup"}"

# Read optional secrets from files
if [ -z $GALERA_PASSWORD ] && [ -f $GALERA_PASSWORD_FILE ]; then
	GALERA_PASSWORD=$GALERA_PASSWORD_FILE
fi

if [ -z $GALERA_PASSWORD ] && [ -f $XTRABACKUP_PASSWORD_FILE ]; then
	GALERA_PASSWORD=$XTRABACKUP_PASSWORD_FILE
fi

if [ -z $GALERA_PASSWORD ]; then
    mysql_useradd.sh -R -u "$GALERA_USER" -p "$GALERA_PASSWORD"
else
    mysql_useradd.sh -R -u "$GALERA_USER" 
fi


echo "Created user $GALERA_USER"

