#!/bin/bash -e

source "mysql_common.sh"
mysql_client=( $(mysql_client) );
${mysql_client[@]} <<< "SET GLOBAL wsrep_provider_options='pc.bootstrap=true';"
