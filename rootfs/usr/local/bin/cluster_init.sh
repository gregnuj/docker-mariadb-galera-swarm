#!/bin/bash -e

[[ -z "$DEBUG" ]] || set -x

source cluster_common.sh

cat <<-EOF > "$(cluster_cnf)" 
[mysqld]
skip_name_resolve

# InnoDB
default_storage_engine = InnoDB
innodb-doublewrite=1 
innodb_file_per_table=1
innodb_autoinc_lock_mode=2
innodb-flush-log-at-trx-commit=2 
#auto_increment_increment = 2
#auto_increment_offset  = 1

# Logs
binlog_format=ROW
log_bin                = /var/log/mysql/mariadb-bin
log_bin_index          = /var/log/mysql/mariadb-bin.index
# not fab for performance, but safer
sync_binlog            = 1
expire_logs_days       = 10
max_binlog_size        = 100M
# slaves
relay_log              = /var/log/mysql/relay-bin
relay_log_index        = /var/log/mysql/relay-bin.index
relay_log_info_file    = /var/log/mysql/relay-bin.info
log_slave_updates
#read_only

# Galera-related settings #
[galera]
wsrep_on=ON
wsrep-node-name=$(service_hostname)
wsrep_node_address=$(node_address)
wsrep-cluster-name=$(cluster_name)
wsrep-cluster-address=gcomm://$(cluster_members)
wsrep_sst_method=$(cluster_sst_method)
wsrep-sst-auth=$(cluster_sst_auth)

wsrep-provider=/usr/lib/galera/libgalera_smm.so
wsrep-provider-options="debug=yes" 
wsrep-provider-options="gcache.size=1G" 
wsrep-provider-options="gcache.page_size=512M" 
wsrep_provider_options="gcache.recover=yes"
wsrep_provider_options="pc.npvo=TRUE"
wsrep_provider_options="pc.wait_prim=TRUE"
wsrep_provider_options="pc.wait_prim_timeout=PT300S"
wsrep_provider_options="pc.weight=$(cluster_weight)"

EOF

echo Created "$(cluster_cnf)"
echo "-------------------------------------------------------------------------"
grep -v "wsrep-sst-auth"  $(cluster_cnf)
echo "-------------------------------------------------------------------------"

