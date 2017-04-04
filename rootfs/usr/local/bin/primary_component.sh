#!/bin/bash -e

mysql_query.sh <<< "SET GLOBAL wsrep_provider_options='pc.bootstrap=true';"
