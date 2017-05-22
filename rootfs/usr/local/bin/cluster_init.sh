#!/bin/bash -e

[[ -z "$DEBUG" ]] || set -x

source cluster_common.sh

cat <<-EOF > "$(cluster_cnf)" 
[mysqld]
#skip_name_resolve

# InnoDB
default_storage_engine = InnoDB
innodb-doublewrite=1 
innodb_file_per_table=1
innodb_autoinc_lock_mode=2
innodb-flush-log-at-trx-commit=2 
innodb_log_file_size=48M
#auto_increment_increment = 2
#auto_increment_offset  = 1

# Logs
log-bin=mysql-bin
expire-logs-days=2
sync-binlog=1
binlog-format=row

# Galera-related settings #
[galera]
wsrep_on=ON
#wsrep-node-name=$(fqdn)
wsrep_node_address=$(node_address)
wsrep-cluster-name=$(cluster_name)
wsrep-cluster-address=$(cluster_address)
wsrep_sst_method=$(cluster_sst_method)
wsrep-sst-auth=$(cluster_sst_auth)

wsrep-provider=/usr/lib/galera/libgalera_smm.so
wsrep-provider-options="debug=yes" 
wsrep-provider-options="gcache.size=1G" 
wsrep-provider-options="gcache.page_size=512M" 
wsrep_provider_options="gcache.recover=yes"
#wsrep_provider_options="pc.npvo=true"
wsrep_provider_options="pc.recovery=true"
wsrep_provider_options="pc.wait_prim=true"
wsrep_provider_options="pc.wait_prim_timeout=PT300S"
#wsrep_provider_options="pc.weight=$(cluster_weight)"

EOF

echo Created "$(cluster_cnf)"
echo "-------------------------------------------------------------------------"
grep -v "wsrep-sst-auth"  $(cluster_cnf)
echo "-------------------------------------------------------------------------"

