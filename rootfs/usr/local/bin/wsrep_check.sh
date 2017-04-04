#!/bin/bash -e

source docker_info.sh

declare SERVICE_NAME="${SERVICE_NAME:="$(service_name)"}"

if [[ -z "$1" ]]; then
	VNAME="wsrep_%"
else
	VNAME="$1"
fi

echo "SHOW GLOBAL STATUS LIKE 'wsrep_%';" |
mysql_query.sh  |
sed -e "s/^/${SERVICE_NAME}: /"
