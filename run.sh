#!/bin/bash

set -e

pull() {
    docker pull percona/percona-xtradb-cluster:5.7
    docker pull pelin/haproxy-keepalived
}

create_mysql_node() {
    NET=mysql-pxc_cluster-network
    docker network create --subnet=172.18.0.0/24 ${NET}

    docker volume create node1-data
    docker volume create node2-data
    docker volume create node3-data

    docker run -tid --expose=3306 --net=${NET} --name=mysql-node-1 \
        -e CLUSTER_NAME=mysql-cluster-test \
        -e MYSQL_ROOT_PASSWORD=a123456 \
        -e XTRABACKUP_PASSWORD=a123456 \
        -v node1-data:/var/lib/mysql \
        --privileged \
        --ip 172.18.0.2 \
        percona/percona-xtradb-cluster:5.7

    sleep 30s

    docker run -tid --expose=3306 --net=${NET} --name=mysql-node-2 \
        -e CLUSTER_NAME=mysql-cluster-test \
        -e MYSQL_ROOT_PASSWORD=a123456 \
        -e XTRABACKUP_PASSWORD=a123456 \
        -e CLUSTER_JOIN=mysql-node-1 \
        -v node2-data:/var/lib/mysql \
        --privileged \
        --ip 172.18.0.3 \
        percona/percona-xtradb-cluster:5.7

    sleep 10s

    docker run -tid --expose=3306 --net=${NET} --name=mysql-node-3 \
        -e CLUSTER_NAME=mysql-cluster-test \
        -e MYSQL_ROOT_PASSWORD=a123456 \
        -e XTRABACKUP_PASSWORD=a123456 \
        -e CLUSTER_JOIN=mysql-node-1 \
        -v node3-data:/var/lib/mysql \
        --privileged \
        --ip 172.18.0.4 \
        percona/percona-xtradb-cluster:5.7

    sleep 10s

    #在MySQL中创建一个没有权限的haproxy用户，密码为空。Haproxy使用这个账户对MySQL数据库心跳检测
    docker exec -it mysql-node-1 sh -c "mysql -uroot -pa123456 -e \"CREATE USER IF NOT EXISTS 'haproxy'@'%' IDENTIFIED BY '';FLUSH PRIVILEGES;\""

    sleep 10s

    docker run -tid -p 4001:8888 -p 4002:3306 --net=${NET} --name haproxy-keepalived1 \
        -v $PWD/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
        -v $PWD/keepalived.cfg:/etc/keepalived/keepalived.conf \
        --privileged \
        --ip 172.18.0.7 \
        pelin/haproxy-keepalived

    sleep 3s

    docker run -tid -p 4003:8888 -p 4004:3306 --net=${NET} --name haproxy-keepalived2 \
        -v $PWD/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
        -v $PWD/keepalived.cfg:/etc/keepalived/keepalived.conf \
        --privileged \
        --ip 172.18.0.8 \
        pelin/haproxy-keepalived
}

clear_cluster() {
    docker stop haproxy-keepalived1
    docker stop haproxy-keepalived2

    docker stop mysql-node-3
    docker stop mysql-node-2
    docker stop mysql-node-1

    docker rm haproxy-keepalived1
    docker rm haproxy-keepalived2

    docker rm mysql-node-3
    docker rm mysql-node-2
    docker rm mysql-node-1

    NET=mysql-pxc_cluster-network
    docker network rm ${NET}

    docker volume rm node3-data
    docker volume rm node2-data
    docker volume rm node1-data
}

rm_cluster_data() {
    docker volume rm mysql-pxc_node1-data
    docker volume rm mysql-pxc_node2-data
    docker volume rm mysql-pxc_node3-data
}

up_cluster() {
    docker-compose -f docker-compose.yml up -d mysql-node-1
    sleep 30s
    docker-compose -f docker-compose.yml up -d
}

down_cluster() {
    docker-compose -f docker-compose.yml down
}

ps_cluster() {
    docker-compose -f docker-compose.yml ps
}

conn_cluster() {
    docker exec -it mysql-node-1 sh -c "mysql -uroot -pa123456"
    #docker exec -it mysql-node-1 sh -c "mysql -uRoyBatty -pRoyBatty2019 -D appdb"
}

case $1 in
    pull)
        pull;;
    create)
        create_mysql_node;;
    clear)
        clear_cluster;;
    rm)
        rm_cluster_data;;
    up)
        up_cluster;;
    ps)
        ps_cluster;;
    down)
        down_cluster;;
    conn)
        conn_cluster;;
    *)
        echo "./run.sh pull|create|clean"
        echo "./run.sh up|ps|down|conn"
esac
