# MariaDb Galera Cluster

This Docker container is based on the official Docker `mariadb:10.1` image and is designed to be
compatible with auto-scheduling systems, specifically Docker Swarm Mode (1.13+).
However, it could also work with manual scheduling (`docker run`) by specifying the correct
environment variables or possibly other scheduling systems that use similar conventions.

By using DNS resolution to discover other nodes they don't have to be specified explicitly. 

### Example (Docker 1.13 Swarm Mode)

```bash
 $ docker service create --name galera --replicas 2 [OPTIONS] [IMAGE] 
```

### Environment Variables

 - maria/mysql vars (`mysql_common.sh`) 
 - `MYSQL_CONFD` (defaults to /etc/mysql/conf.d)
 - `MYSQL_DATABASE` (optional - defaults to substring before - in `SERVICE_NAME`)
 - `MYSQL_PASSWORD` (optional - defaults to hash based on `MYSQL_USER` and `MYSQL_ROOT_PASSSWORD`)
 - `MYSQL_ROOT_PASSWORD` (optional - defaults to random)
 - `MYSQL_USER` (optional - dfaults to `MYSQL_DATABASE` name)
 - `DATADIR` (defaults to /var/lib/mysql)

 - cluster vars (`cluster_common.sh`)
 - `CLUSTER_CNF` (optional - defaults to `$MYSQL_CONFD`)
 - `CLUSTER_MEMBERS` (optional - comma seperated list)
 - `CLUSTER_MINIMUM` (optional defaults to 2)
 - `CLUSTER_NAME` (optional - defaults to `$SERVICE_NAME-cluster`)
 - `CLUSTER_POSITION` (defaults to `$CLUSTER_UUID:$CLUSTER_SEQNO`)
 - `CLUSTER_PRIMARY` (optional - defaults to lowest ip in cluster)
 - `CLUSTER_SEQNO` (defaults to seqno value in grastate.dat)
 - `CLUSTER_SST_METHOD`
 - `CLUSTER_STB` (defaults to `safe_to_bootstrap` value in grastate.dat)
 - `CLUSTER_UUID` (defaults to uuid value in grastate.dat)
 - `CLUSTER_WEIGHT` (defaults to ip sort order)
 - `GRASTATE_DAT` (defaults to $DATADUR/grastate.dat)
 - `WSREP_PASSWORD` (optional - defaults to hash based on WSREP_USER and MYSQL_ROOT_PASSSWORD)
 - `WSREP_USER` (optional - defaults to xtrabackup)


 - Docker swarm vars (`swarm_common.sh`)
 - `CONTAINER_NAME` (defaults to coantiner name in stack/compose file)
 - `FQDN` (defaults to eth0 docker dns fqdn)
 - `NODE_ADDRESS` (optional - defaults to ip address of eth0)
 - `SERVICE_COUNT` (optional - defaults to number of SERVICE_MEMBERS)
 - `SERVICE_HOSTNAME` (optional defaults to docker dns name)
 - `SERVICE_INSTANCE` (optional - defaults to service container number)
 - `SERVICE_MEMBERS` (optional - defaults to comma seperated list of ip's in service)
 - `SERVICE_NAME` (optional - defaults to docker service name )


#### Providing secrets through files

It's also possible to configure the sensitive variables (especially passwords)
by providing files. This makes it easier, for example, to integrate with
[Docker Swarm's secret support](https://docs.docker.com/engine/swarm/secrets/)
added in Docker 1.13.0.

The path to the secret file may be provided in environment variables:
- `MYSQL_ROOT_PASSWORD_FILE` (optional)
- `MYSQL_PASSWORD_FILE` (optional)

#### Automatic integration with [Docker Swarm's secret support](https://docs.docker.com/engine/swarm/secrets/)

Note: manually setting any of these values via ENV overides the use of the secret files.

### Credit
 - ["toughIQ/docker-mariadb-cluster"](https://github.com/toughIQ/docker-mariadb-cluster) 
 - ["colinmollenhour/mariadb-galera-swarm"](https://github.com/colinmollenhour/mariadb-galera-swarm)
 - ["jakolehm/docker-galera-mariadb-10.0"](https://github.com/jakolehm/docker-galera-mariadb-10.0)
 - ["sttts/docker-galera-mariadb-10.0"](https://github.com/sttts/docker-galera-mariadb-10.0)

