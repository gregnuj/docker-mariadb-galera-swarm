#!/bin/bash -e

# Set 'DEBUG=1' environment variable to see detailed output for debugging
if [[ ! -z "$DEBUG" && "$DEBUG" != 0 && "${DEBUG^^}" != "FALSE" ]]; then
  set -x
fi

source docker_info.sh
source mysql_info.sh

# Defaults to servicename-cluster
function cluster_name(){
    CLUSTER_NAME="${CLUSTER_NAME:="$(service_name)-cluster"}"
    echo "${CLUSTER_NAME}"
}

# Defaults to /var/lib/mysql/grastate.dat
function grastate_dat(){
    GRASTATE_DAT="${GRASTATE_DAT:="$(mysql_dir)/grastate.dat"}"
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
function cluster_user(){
    CLUSTER_USER="${CLUSTER_USER:="xtrabackup"}"
    echo "${CLUSTER_USER}"
}

#
function cluster_sst_method(){
    CLUSTER_SST_METHOD="${CLUSTER_SST_METHOD:="xtrabackup"}"
    echo "${CLUSTER_SST_METHOD}"
}

#
function cluster_sst_auth(){
    CLUSTER_SST_AUTH="${CLUSTER_SST_AUTH:="$(mysql_auth "$(cluster_user)")"}"
    echo "${CLUSTER_SST_AUTH}"
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

function cluster_bootstrap(){
    if [[ -f $(grastate_dat) ]]; then
        CLUSTER_BOOTSTRAP=0
    elif [[ $(cluster_primary) == $(node_address) ]]; then
        CLUSTER_BOOTSTRAP=1
    else
        CLUSTER_BOOTSTRAP=0
    fi
    echo "$CLUSTER_BOOTSTRAP"
}

function main(){
    case "$1" in
        -a|--address)
            echo "$(cluster_address)"
            ;;
        --auth)
            echo "$(cluster_sst_auth)"
            ;;
        -d|--dir)
            echo "$(datadir)"
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
            echo "$(cluster_user)"
            ;;
        -w|--weight)
            echo "$(cluster_weight)"
            ;;
    esac
}

main "$@"
