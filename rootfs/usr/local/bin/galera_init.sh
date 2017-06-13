#!/bin/bash -e

[[ -z "$DEBUG" ]] || set -x

source galera_common.sh

cat <<-EOF > "$(galera_cnf)" 
[mysqld]
log-error=/dev/stderr
skip_name_resolve

# InnoDB
default_storage_engine = InnoDB
innodb-doublewrite=1 
innodb_file_per_table=1
innodb_autoinc_lock_mode=2
innodb-flush-log-at-trx-commit=0 
innodb_log_file_size=48M

# Logs
sync-binlog=0
log-bin=binlog
binlog-format=row

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
wsrep_provider_options="evs.suspect_timeout = PT30S"
wsrep_provider_options="evs.inactive_timeout = PT1M"
wsrep_provider_options="evs.install_timeout = PT1M"
wsrep_provider_options="evs.max_install_timeouts=10"
wsrep_provider_options="evs.user_send_window=512"
wsrep_provider_options="evs.send_window=1024"
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

