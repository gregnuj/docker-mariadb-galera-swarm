#!/bin/bash -e

[[ -z "$DEBUG" ]] || set -x

source galera_common.sh

cat <<-EOF > "$(galera_cnf)" 
[mysqld]
log-error=/dev/stderr
skip_name_resolve

# InnoDB
default_storage_engine = InnoDB
innodb_autoinc_lock_mode=2
innodb-buffer-pool-size=26G
innodb_file_per_table=1
innodb-flush-log-at-trx-commit=0 
innodb-flush-method=O_DIRECT
innodb_locks_unsafe_for_binlog=1
innodb-log-file-size=512M
innodb-log-files-in-group=2

# Logs
binlog-format=row
log-bin=binlog
sync-binlog=0
log_slave_updates
log-error = /var/log/mysql/mysql-error.log
log-queries-not-using-indexes=1
slow-query-log = 1
slow-query-log-file = /var/log/mysql/mysql-slow.log

# Galera-related settings #
[galera]
wsrep_on=ON
#wsrep-node-name=$(wsrep_node_name)
wsrep_node_address=$(wsrep_node_address)
wsrep-cluster-name=$(wsrep_cluster_name)
wsrep-cluster-address=$(wsrep_cluster_address)
wsrep-max-ws-size=1024K
wsrep_slave_threads=4

wsrep_sst_method=$(wsrep_sst_method)
wsrep-sst-auth=$(wsrep_sst_auth)

wsrep-provider=/usr/lib/galera/libgalera_smm.so
wsrep-provider-options="debug=${WSREP_DEBUG}" 
wsrep_provider_options="evs.keepalive_period = PT3S"
wsrep_provider_options="evs.suspect_timeout = P60S"
wsrep_provider_options="evs.inactive_timeout = PT60S"
wsrep_provider_options="evs.install_timeout = PT60S"
wsrep_provider_options="evs.max_install_timeouts=10"
wsrep_provider_options="evs.user_send_window=1024"
wsrep_provider_options="evs.send_window=2048"
wsrep-provider-options="gcache.size=1G" 
wsrep-provider-options="gcache.page_size=512M" 
wsrep_provider_options="gcache.recover=yes"
wsrep_provider_options="pc.recovery=true"
#wsrep_provider_options="pc.npvo=true"
wsrep_provider_options="pc.wait_prim=true"
wsrep_provider_options="pc.wait_prim_timeout=PT300S"
wsrep_provider_options="pc.weight=$(wsrep_pc_weight)"

[sst]
progress=1
streamfmt=xbstream

EOF

echo Created "$(galera_cnf)"
echo "-------------------------------------------------------------------------"
grep -v "wsrep-sst-auth"  $(galera_cnf)
echo "-------------------------------------------------------------------------"

