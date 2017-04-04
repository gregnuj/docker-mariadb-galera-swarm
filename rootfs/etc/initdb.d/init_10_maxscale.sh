#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
  set -x
fi

declare MAXSCALE_USER="${MAXSCALE_USER:="maxscale"}"

# Read optional secrets from files
if [ -z $MAXSCALE_PASSWORD ] && [ -f $MAXSCALE_PASSWORD_FILE ]; then
	MAXSCALE_PASSWORD=$MAXSCALE_PASSWORD_FILE
fi

if [ -z $MAXSCALE_PASSWORD ]; then
    mysql_useradd.sh -s "system" -u "$MAXSCALE_USER" -p "$MAXSCALE_PASSWORD"
else
    mysql_useradd.sh -s "system" -u "$MAXSCALE_USER" 
fi


echo "Created user $MAXSCALE_USER"


