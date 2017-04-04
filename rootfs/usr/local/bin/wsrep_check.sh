#!/bin/bash -e

source swarm_common.sh
source mysql_common.sh

if [[ -z "$1" ]]; then
	VNAME="wsrep_%"
else
	VNAME="$1"
fi

echo "SHOW GLOBAL STATUS LIKE '$VNAME';" |
( $(mysql_client) )  |
sed -e "s/^/$(service_name): /"
