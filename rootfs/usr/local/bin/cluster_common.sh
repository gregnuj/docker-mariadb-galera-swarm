#!/bin/bash -e
#

[[ -z "$DEBUG" ]] || set -x

source swarm_common.sh
source mysql_common.sh

# Defaults to servicename-cluster
function cluster_name(){
    CLUSTER_NAME="${CLUSTER_NAME:="$(service_name)-cluster"}"
    echo "${CLUSTER_NAME}"
}

# Defaults to galera_auto.cnf
function cluster_cnf(){
    CLUSTER_CNF="${CLUSTER_CNF:="$(mysql_confd)/galera_auto.cnf"}"
    echo "${CLUSTER_CNF}"
}

# Defaults to /var/lib/mysql/grastate.dat
function grastate_dat(){
    GRASTATE_DAT="${GRASTATE_DAT:="$(mysql_datadir)/grastate.dat"}"
    if [[ -f "$GRASTATE_DAT" ]]
        CLUSTER_UUID="$(awk '/^uuid:/{print $2}' $GRASTATE_DAT)"
        CLUSTER_STB="$(awk '/^safe_to_bootstrap:/{print $2}' $GRASTATE_DAT)"
        CLUSTER_SEQNO="$(awk '/^seqno:/{print $2}' $GRASTATE_DAT)"
    else
	CLUSTER_UUID='00000000-0000-0000-0000-000000000000'
	CLUSTER_SEQNO=-1
	CLUSTER_STB=0
    fi
    echo "${GRASTATE_DAT}"
}

# Defaults to 2
function cluster_minimum(){
    CLUSTER_MINIMUM="${CLUSTER_MINIMUM:="2"}"
    echo $((CLUSTER_MINIMUM))
}

# Built from cluster members
function cluster_address(){
    CLUSTER_ADDRESS="${CLUSTER_ADDRESS:="gcomm://$(cluster_members)"}"
    echo "${CLUSTER_ADDRES}"
}

#
function cluster_sst_method(){
    CLUSTER_SST_METHOD="${CLUSTER_SST_METHOD:="xtrabackup"}"
    echo "${CLUSTER_SST_METHOD}"
}

function wsrep_user(){
    WSREP_USER="${WSREP_USER:="xtrabackup"}"
    echo "${WSREP_USER}"
}

function wsrep_password(){
    WSREP_PASSWORD="${WSREP_PASSWORD:="$(mysql_password "$(wsrep_user)")"}"
    echo "${WSREP_PASSWORD}"
}

#
function cluster_sst_auth(){
    WSREP_USER="$(wsrep_user)"
    WSREP_PASSWORD="$(wsrep_password)"
    echo "${USER}:${PASSWORD}"
}


# discovered from docker_info.SERVICE_MEMBERS using CLUSTER_MINIMUM 
function cluster_members(){
    CLUSTER_MINIMUM=$(cluster_minimum)
    while [[ -z "${CLUSTER_MEMBERS}" ]]; do
       CURRENT_MEMBERS="$(service_members)"
       COUNT="$(service_count)"
       echo "Found ($COUNT) members in ${SERVICE_NAME} ($CURRENT_MEMBERS)" >&2
       if [[ $COUNT -lt $(($CLUSTER_MINIMUM)) ]]; then
           echo "Waiting for at least $CLUSTER_MINIMUM IP addresses to resolve..." >&2
           SLEEPS=$((SLEEPS + 1))
           sleep 3
       else
           CLUSTER_MEMBERS="$CURRENT_MEMBERS"
       fi

       # After 90 seconds reduce SERVICE_ADDRESS_MINIMUM
       if [[ $SLEEPS -ge 30 ]]; then
          SLEEPS=0
          CLUSTER_MINIMUM=$((CLUSTER_MINIMUM - 1))
          echo "Reducing CLUSTER_MINIMUM to $CLUSTER_MINIMUM" >&2
       fi
       if [[ $CLUSTER_MINIMUM -lt 2 ]]; then
          echo "CLUSTER_MINIMUM is $CLUSTER_MINIMUM cannot continue" >&2
          exit 1
       fi
    done
    echo "${CLUSTER_MEMBERS}"
}

function cluster_mem_names(){
    NAMES=()
    FS=',' read -r -a members <<< "$(cluster_members)" 
    for member in $members; do 
        NAMES+="$(nslookup "$(member)" | awk -F'= ' 'NR==5 { print $2 }')"
    done
    echo "${NAMES[@]}"
}

# Defaults to lowest ip in Cluster members
function cluster_primary(){
    if [[ -z "${CLUSTER_PRIMARY}" ]]; then
        CLUSTER_PRIMARY=$(echo "$(cluster_members)" | tr ',' '\n' | sort -r | tail -n 1)
    fi
    echo "${CLUSTER_PRIMARY}"
}

# Defaults 
function cluster_weight(){
    CLUSTER_WEIGHT=$(echo "$(cluster_members)" | tr ',' '\n' | sort -r | awk "/$(node_address)/ {print FNR}")
    echo $((CLUSTER_WEIGHT % 255))
}

function cluster_seqno(){
    if [[ -z "${CLUSTER_SEQNO}" ]]; then :
        GRASTATE_DAT="$(grastate_dat)"
    else
    fi
    echo "$CLUSTER_SEQNO"
}

function cluster_uuid(){
    if [[ -z "${CLUSTER_UUID}" ]]; then :
        GRASTATE_DAT="$(grastate_dat)"
    fi
    echo "$CLUSTER_UUID"
}

function cluster_stb(){
    GRASTATE_DAT="$(grastate_dat)"
    if [[ -z "${CLUSTER_STB}" ]]; then 
        GRASTATE_DAT="$(grastate_dat)"
    fi
    echo "$CLUSTER_STB"
}

function cluster_position(){
    CLUSTER_POSITION="$(cluster_uuid):$(cluster_seqno)"
    echo "$CLUSTER_POSITION" 
}

function main(){
    case "$1" in
        -a|--address)
            echo "$(cluster_address)"
            ;;
        --auth)
            echo "$(cluster_sst_auth)"
            ;;
        -f|--fqdn)
            echo "$(fqdn)"
            ;;
        -m|--members)
            echo "$(cluster_members)"
            ;;
        --method)
            echo "$(cluster_sst_method)"
            ;;
        --minimum)
            echo "$(cluster_minimum)"
            ;;
        -n|--name)
            echo "$(cluster_name)"
            ;;
        -p|--primary)
            echo "$(cluster_primary)"
            ;;
        -u|--user)
            echo "$(wsrep_user)"
            ;;
        -w|--weight)
            echo "$(cluster_weight)"
            ;;
    esac
}

main "$@"


