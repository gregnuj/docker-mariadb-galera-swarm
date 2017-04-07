#!/bin/bash -e
#

[[ -z "$DEBUG" ]] || set -x

source mysql_common.sh
source cluster_common.sh
declare MYSQLD=( $@ )

function mysql_init_install(){
    mkdir -p "$(mysql_datadir)"
    mysql_install_db --user=mysql --datadir="$(mysql_datadir)" --rpm 
}

function mysql_init_start(){
    "${MYSQLD[@]}" --skip-networking --socket=/var/run/mysqld/mysqld.sock &
    PID="$!"
}

function mysql_init_client(){
    mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock )
    if [ ! -z "$MYSQLD_INIT_ROOT" ]; then
        mysql+=( -p"${MYSQLD_INIT_ROOT}" )
    fi
    echo "${mysql[@]}"
}

function mysql_init_check(){
    mysql=( $(mysql_init_client) )
    for i in {30..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            break
        fi
        echo 'MySQL init process in progress...'
        sleep 2
    done
    if [[ "$i" = "0" ]]; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi
}

function mysql_init_root(){
    mysql=( $(mysql_init_client) )
    sql=( "SET @@SESSION.SQL_LOG_BIN=0;" )
    sql+=( "DELETE FROM mysql.user ;" )
    sql+=( "CREATE USER 'root'@'%' IDENTIFIED BY '$(mysql_password root)' ;" )
    sql+=( "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;" )
    sql+=( "DROP DATABASE IF EXISTS test ;" )
    sql+=( "FLUSH PRIVILEGES ;" )
    echo "${sql[@]}" | "${mysql[@]}"
    MYSQLD_INIT_ROOT=1
}

function mysql_init_tz(){
    mysql=( $(mysql_client) )
    if [[ -z "$MYSQL_INITDB_SKIP_TZINFO" ]]; then
        # sed is for https://bugs.mysql.com/bug.php?id=20545
        mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
    fi
}

function mysql_init_database(){
    mysql=( $(mysql_client) )
    SERVICE_NAME="${SERVICE_NAME:="$(service_name)"}"
    MYSQL_DATABASE="${MYSQL_DATABASE:="${SERVICE_NAME%-*}"}"
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
}

function mysql_init_user(){
    mysql=( $(mysql_client) );
    SERVICE_NAME="${SERVICE_NAME:="$(service_name)"}"
    MYSQL_DATABASE="${MYSQL_DATABASE:="${SERVICE_NAME%-*}"}"
    MYSQL_USER="${MYSQL_USER:="${MYSQL_DATABASE}"}"
    MYSQL_PASSWORD="$(mysql_password $MYSQL_USER)"
    echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" | "${mysql[@]}"
    echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
    echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
    echo "Created user $MYSQL_USER"
}

function mysql_init_wsrep(){
    mysql=( $(mysql_client) );
    WSREP_USER="${WSREP_USER:="$(wsrep_user)"}"
    WSREP_PASSWORD="${WSREP_PASSWORD:="$(mysql_password $WSREPL_USER)"}"
    echo "CREATE USER IF NOT EXISTS '${WSREP_USER}'@'127.0.0.1' IDENTIFIED BY '${WSREP_PASSWORD}';" | "${mysql[@]}"
    echo "GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO '${WSREP_USER}'@'127.0.0.1';"    | "${mysql[@]}"
    echo "CREATE USER IF NOT EXISTS '${WSREP_USER}'@'localhost' IDENTIFIED BY '${WSREP_PASSWORD}';" | "${mysql[@]}"
    echo "GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO '${WSREP_USER}'@'localhost';"    | "${mysql[@]}"
    echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
    echo "Created user $WSREP_USER"
}

function mysql_init_scripts(){
    mysql=( $(mysql_client) )
    for f in /etc/initdb.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
            *)        echo "$0: ignoring $f" ;;
         esac
         echo
    done
}

function main(){
    echo "Initailizing new database"
    mysql_init_install
    mysql_init_start
    mysql_init_check 
    mysql_init_root 
    mysql_init_tz 
    mysql_init_user 
    mysql_init_database
    mysql_init_wsrep
    mysql_init_scripts 
    mysql_shutdown
    echo "Initailizing database completed"
}

main
