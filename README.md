# Docker MySQL MHA

基于Docker 1.13.1之上构建的MySQL MHA Docker Compose Project

可快速启动GTID模式下的MasterHA集群, 主用于MySQL与Docker的学习研究

## 构建环境

- MacOS 10.12.3
- Docker 1.13.1
- Docker Compose 1.11.1
- Docker image for MySQL 5.7.17
- Docker image for Debian jessie
- mha4mysql-manager-0.56
- mha4mysql-node-0.56

## 特性

- USTC debian sources
- 自动生成MySQL复制账户与MHA工作账户
- 可自定义的MySQL复制与MHA工作账户信息
- SSH key的自动生成
- 容器间的SSH key相互复制与SSH免密登录
- MasterHA的自启动

## 构建与启动

### docker-compose.yml 定义

`master` - Docker compose中名为`master`的service, 主库容器默认映射端口3406

`slave_1` - Docker compose中名为`slave_1`的service, 从库容器默认映射端口3407

`manager` - Docker compose中名为`manager`的service, 作为MHA manager

`mha_share` - 容器间的共享数据卷

### 目录与文件功能说明

- account.env

  保存容器间的公用环境变量, 如MySQL复制账户repl的账号密码

- employees_db

  `master` 启动时的MySQL初始化脚本

- employees_master

  `master` 主库容器中的配置文件, 日志与库存放位置

- employees_slave_1

  `slave_1` 从库容器中的配置文件, 日志与库存放位置

- employees_share

  容器间的共享数据卷

- mha_manager

  构建Docker镜像`mha_manager`所需的Dockerfile及其依赖文件的存放目录, 在docker-compose.yml有定义

- mha_node

  构建Docker镜像`mha_node`所需的Dockerfile及其依赖文件的存放目录, 在docker-compose.yml有定义

- reset.sh

  停止project并删除所有数据库的日志与库(配置文件除外)

- shutdown.sh

  单纯地停止project

- start.sh

  1. 启动project
  2. 在各个容器中生成ssh key
  3. 将ssh key分别复制到其他容器中, 使得容器之间都可以使用SSH免密登录
  4. 使`master`与`slave_1`形成复制链路
  5. 根据自定义的MySQL账户密码生成MHA配置文件
  6. masterha_check_ssh检测容器间的SSH正确性
  7. masterha_check_repl检测复制的健康状况
  8. 启动masterha_manager并将日志写入employees_share中的`mha.log`

### 启动

1. **首次运行时**请先初始化MySQL, 否则容器将不接受连接

   ```shell
   ➜  mha git:(master) docker-compose up -d
   Creating network "mha_default" with the default driver
   Creating mha_mha_node_1
   Creating mha_mha_share_1
   Creating mha_mha_manager_1
   Creating mha_master_1
   Creating mha_slave_1_1
   Creating mha_manager_1
   ```

   待容器可接收宿主机的MySQL连接代表初始化完成

2. 预热后运行start.sh脚本以构建MHA集群

   ```shell
   ➜  mha git:(master) ./start.sh
   >>> Docker Compose starting...
   Starting mha_mha_manager_1
   Starting mha_mha_share_1
   Starting mha_mha_node_1
   mha_master_1 is up-to-date
   mha_slave_1_1 is up-to-date
   mha_manager_1 is up-to-date
   >>> Setting ssh...
   fd9686976e61 initializing SSH...
   fd9686976e61 change the password of root successfully.
   fd9686976e61 SSH service has been restarted.
   fd9686976e61 succeed in generating ssh key.
   ...
   fd9686976e61 copy ssh key to manager successfully.
   fd9686976e61 copy ssh key to master successfully.
   ...
   >>> Creating mysql user for replication named 'repl' on master container...
   mysql: [Warning] Using a password on the command line interface can be insecure.
   >>> Configuring replication with GTID mode...
   configuring slave_1 754214d5bdfc ...
   mysql: [Warning] Using a password on the command line interface can be insecure.
   >>> Initializing MHA configuration...
   mha configuration "/mha_share/application.cnf" is not initialized.
   added host "master" to mha configuration file.
   added host "slave_1" to mha configuration file.
   **********************************************
   checking mha ssh...
   Wed Feb 15 11:04:08 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
   ...
   Wed Feb 15 11:04:08 2017 - [debug]   ok.
   Wed Feb 15 11:04:09 2017 - [info] All SSH connection tests passed successfully.
   **********************************************
   checking mha repl to mysql...
   Wed Feb 15 11:04:09 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
   ...
   MySQL Replication Health is OK.
   **********************************************
   starting mha manager with file "/mha_share/application.cnf"...
   nohup: redirecting stderr to stdout
   >>> Done!
   ```

   > NOTE: 首次运行时如果不预热而直接调用start.sh脚本的话, 则会引起MySQL未完成初始化而造成构建主从复制链路出错, 如果是数据库已经经过初始化则不需要进行预热

## 注意事项

1. 首次运行时请先运行`docker-compose up -d`进行MySQL的初始化
2. 一个Docker Compose Service对应一个容器, 以此享用Docker Compose默认构建的容器网络, 即可直接使用service name进行SSH通信
3. 本项目仅用于学习MySQL MHA集群, 同时练习Docker的使用
4. 要使用虚拟IP的话可自行搭配Keepalive, LVS等

## 参考

[MHA Quick Start Guide](https://www.percona.com/blog/2016/09/02/mha-quickstart-guide/)

[MySQL Docker Image](https://hub.docker.com/_/mysql/)

[Two-way link with Docker Compose](https://medium.com/@tristan.claverie/well-there-is-in-fact-a-simpler-solution-than-creating-a-network-do-nothing-at-all-docker-f38e93326134#.l6uupkacv)

[How to configure MySQL master/slave replication with MHA automatic failover](http://www.arborisoft.com/how-to-configure-mysql-masterslave-replication-with-mha-automatic-failover/)