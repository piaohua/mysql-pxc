# mysql-pxc
Percona XtraDB Cluster on docker-compose

# Usage

```
拉取镜像
sh ./run pull

docker启动集群
sh ./run create

查看启动容器
docker ps --format="table{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}"

or

docker-compose启动集群
sh ./run up

查看启动集群容器状态
sh ./run ps

浏览器中打开登录,账号信息(admin:abc123456)
HAProxy (http://localhost:4001/dbs)
```

# License

MIT.
