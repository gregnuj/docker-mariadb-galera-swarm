#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
  set -x
fi

source mysql_info.sh

declare ADD_USER=""
declare ADD_GROUP="%"
declare ADD_PASSWORD=""
declare ADD_DATABASE="${MYSQL_DATABASE:=""}"
declare ADD_CREATE_DATABASE="${ADD_CREATE_DATABASE:=""}"
declare ADD_SCOPE="user"
declare ADD_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:=""}"
declare ADD_SEED=""

usage(){
    echo "($basename $0) - Approximation of useradd for maraidb/mysql"
    echo "Usage: mysql_useradd [options] LOGIN"
    #echo "       useradd -D"
    #echo "       useradd -D [options]"
    echo ""
    echo "Options:"
    #echo "  -b, --base-dir BASE_DIR       base directory for the home directory of the"
    #echo "                                new account"
    #echo "  -c, --comment COMMENT         GECOS field of the new account"
    echo "  -d, --database                home database of the new account"
    #echo "  -D, --defaults                print or change default useradd configuration"
    #echo "  -e, --expiredate EXPIRE_DATE  expiration date of the new account"
    #echo "  -f, --inactive INACTIVE       password inactivity period of the new account"
    echo "  -g, --group GROUP             name of the primary group of the newaccount "
    echo "                                (EXAMPLES: localhost, 127.0.0.1, or %)"
    #echo "  -G, --groups GROUPS            name of the groups of the new account"
    #echo "                                (localhost, 127.0.0.1, %)"
    echo "  -h, --help                    display this help message and exit"
    #echo "  -k, --skel SKEL_DIR           use this alternative skeleton directory"
    #echo "  -K, --key KEY=VALUE           override /etc/login.defs defaults"
    #echo "  -l, --no-log-init             do not add the user to the lastlog and"
    #echo "                                faillog databases"
    echo "  -m, --create-home             create the user's home database"
    echo "  -M, --no-create-home          do not create the user's home database"
    #echo "  -N, --no-user-group           do not create a database with the same name as"
    #echo "                                the user"
    #echo "  -o, --non-unique              allow to create users with duplicate"
    #echo "                                (non-unique) UID"
    echo "  -p, --password PASSWORD       password of the new account"
    echo "  -P, --root-password PASSWORD  password of the root account"
    echo "  -r, --system                  create a system admin account"
    echo "  -R, --replication             create a replicaation account"
    echo "  -s, --scope                   create a specified type of account"
    echo "                                (admin, user, replication)"
    echo "  -u, --user NAME               user name of the new account"
    echo "  -U, --create-user NAME        create a user and database with the same name"
    #echo "  -Z, --selinux-user SEUSER     use a specific SEUSER for the SELinux user mapping"
}

croak(){
    echo "($basename $0): $1" >&2
    echo "Try \`($basename $0) --help' for more information." >&2
    exit 1 
}

while [[ -n "$@" ]]; do
    case "$1" in
        -d|--database)
            shift
            ADD_DATABASE="$1"
            ;;
        -h|--help)
            shift
            usage 
            exit
            ;;
        -m|--create-home)
            ADD_CREATE_DATABASE="truedat"
            ;;
        -M|--no-create-home)
            ADD_CREATE_DATABASE=""
            ;;
        -p|--password)
            shift
            ADD_PASSWORD="$1"
            ;;
        -P|--root-password)
            shift
            ADD_ROOT_PASSWORD="$1"
            ;;
        -r|--system)
            ADD_SCOPE="admin"
            ;;
        -R|--replication)
            ADD_SCOPE="replication"
            ;;
        -s|--scope)
            shift
            ADD_SCOPE="$1"
            ;;
        -u|--user)
            shift
            ADD_USER="$1"
            ;;
        -U|--create-user)
            shift
            ADD_USER="$1"
            ADD_DATABASE="$1"
            ADD_CREATE_DATABASE="truedat"
            ;;
        *)
            ADD_USER="$1"
            ;;
    esac
    shift
done

# Check user value
if [[ -z "${ADD_USER}" ]]; then
    croak "no user specified"
fi

if [[ -z "${ADD_PASSWORD}" ]]; then
    ADD_PASSWORD="$(mysql_password $ADD_USER)"
fi

# Check 
if [[ -e /var/run/mysqld/mysqld.sock ]]; then
	mysql=( $(mysql_admin) )
	
	## <<-EOSQL requires tabs
	if [[ "$ADD_SCOPE" == "super" ]]; then
		"${mysql[@]}" <<-EOSQL
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'localhost' IDENTIFIED BY '${ADD_PASSWORD}';
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'127.0.0.1' IDENTIFIED BY '${ADD_PASSWORD}';
			GRANT ALL ON *.* TO '$ADD_USER'@'localhost' WITH GRANT OPTION '${ADD_PASSWORD}';
			GRANT ALL ON *.* TO '$ADD_USER'@'127.0.01' WITH GRANT OPTION '${ADD_PASSWORD}';
			FLUSH PRIVILEGES;
		EOSQL
	elif [[ "$ADD_SCOPE" == "replication" ]]; then
		"${mysql[@]}" <<-EOSQL
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'localhost' IDENTIFIED BY '${ADD_PASSWORD}';
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'127.0.0.1' IDENTIFIED BY '${ADD_PASSWORD}';
			GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO '${ADD_USER}'@'localhost';
			GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO '${ADD_USER}'@'127.0.0.1';
			FLUSH PRIVILEGES;
		EOSQL
	elif [[ "$ADD_SCOPE" == "system" ]]; then
		"${mysql[@]}" <<-EOSQL
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'localhost' IDENTIFIED BY '${ADD_PASSWORD}';
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'127.0.0.1' IDENTIFIED BY '${ADD_PASSWORD}';
			GRANT PROCESS,SHUTDOWN ON *.* TO '${ADD_USER}'@'localhost';
			GRANT PROCESS,SHUTDOWN ON *.* TO '${ADD_USER}'@'127.0.0.1';
			FLUSH PRIVILEGES;
		EOSQL
	elif [[ -z "${ADD_DATABASE}" ]]; then
		"${mysql[@]}" <<-EOSQL
			CREATE USER IF NOT EXISTS '${ADD_USER}'@'$ADD_GROUP' IDENTIFIED BY '${ADD_PASSWORD}';
			FLUSH PRIVILEGES;
		EOSQL
	elif [[ -z "${ADD_CREATE_DATABASE}" ]]; then
		"${mysql[@]}" <<-EOSQL
			GRANT ALL ON ${ADD_DATABASE}.* TO '${ADD_USER}'@'%' IDENTIFIED BY '${ADD_PASSWORD}';
			FLUSH PRIVILEGES;
		EOSQL
	else
		"${mysql[@]}" <<-EOSQL
			CREATE DATABASE IF NOT EXISTS \`${ADD_DATABASE}\` ;
			GRANT ALL ON ${ADD_DATABASE}.* TO '${ADD_USER}'@'%' IDENTIFIED BY '${ADD_PASSWORD}';
			FLUSH PRIVILEGES;
		EOSQL
	fi
fi	


# Output result
echo "$ADD_USER:$ADD_PASSWORD"
