# MariaDb Galera Cluster

This Docker container is based on the official Docker `mariadb:10.1` image and is designed to be
compatible with auto-scheduling systems, specifically Docker Swarm Mode (1.13+).
However, it could also work with manual scheduling (`docker run`) by specifying the correct
environment variables or possibly other scheduling systems that use similar conventions.

By using DNS resolution to discover other nodes they don't have to be specified explicitly. 

### Example (Docker 1.12 Swarm Mode)

```bash
 $ docker service create --name galera --replicas 2 [OPTIONS] [IMAGE] 
 $ docker service scale galera=5
```

### Environment Variables

 - `GALERA_PASSWORD` or `XTRABACKUP_PASSWORD` (optional - defaults to hash of `ROOT_PASSWORD`)
 - `SYSTEM_PASSWORD` (optional - defaults to hash of `ROOT_PASSWORD`)
 - `SERVICE_NAME` (optional - defaults to docker name
 - `CLUSTER_NAME` (optional - defaults to `SERVICE_NAME-cluster`)
 - `NODE_ADDRESS` (optional - defaults to ethwe, then eth0)

Additional variables for "seed":

 - `MYSQL_ROOT_PASSWORD` (optional)
 - `MYSQL_DATABASE` (optional)
 - `MYSQL_USER` (optional - defaults to `MYSQL_DATABASE`)
 - `MYSQL_PASSWORD` (optional - defaults to hash of `ROOT_PASSWORD`)

Additional variables for "node":

 - `GCOMM_MINIMUM` (optional - defaults to 2)

#### Providing secrets through files

It's also possible to configure the sensitive variables (especially passwords)
by providing files. This makes it easier, for example, to integrate with
[Docker Swarm's secret support](https://docs.docker.com/engine/swarm/secrets/)
added in Docker 1.13.0.


Otherwise the path to the secret file may be provided in environment variables:
- `MYSQL_ROOT_PASSWORD_FILE` (optional)
- `MYSQL_PASSWORD_FILE` (optional)

#### Automatic integration with [Docker Swarm's secret support](https://docs.docker.com/engine/swarm/secrets/)

Note: manually setting any of these values via ENV overides the use of the secret files.

### Credit
 - Some code from ["toughIQ/docker-mariadb-cluster"](https://github.com/toughIQ/docker-mariadb-cluster) 
 - Forked from ["colinmollenhour/mariadb-galera-swarm"](https://github.com/colinmollenhour/mariadb-galera-swarm)
 - Forked from ["jakolehm/docker-galera-mariadb-10.0"](https://github.com/jakolehm/docker-galera-mariadb-10.0)
   - Forked from ["sttts/docker-galera-mariadb-10.0"](https://github.com/sttts/docker-galera-mariadb-10.0)

### Changes

