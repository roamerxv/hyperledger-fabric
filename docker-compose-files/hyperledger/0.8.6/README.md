在CentOS 7.2下安装Hyperledger fabric 1.0.0 preview版本（solo共识模式）
## 一. 安装centos和docker 等组件
### A. 安装centos x86-64 Minimal(IP:192.168.2.10)
内核版本需要3.10 以上。centos 7 完全支持.

```
查看内核信息
$ uname -a
Linux localhost.localdomain 3.10.0-514.6.1.el7.x86_64
```

### B. 安装docker， 版本1.12.5（略过）

```
$ docker -v
Docker version 1.12.5, build 047e51b/1.12.5
```

### C. 安装python-pip(可选)
* 安装epel扩展

```
$ yum -y install epel-release
```

* 然后安装python-pip

```
$ yum -y install python-pip
# 更新到最新版本
$ pip install --upgrade pip
```

* 确认安装成功和确定版本

```
$ pip -V
```

### d. 安装docker-compose
docker-compose是docker集群管理工具，可自定义一键启动多个docker container。
官网二进制发布:
https://github.com/docker/compose/releases
安装手册见网站 : 
https://docs.docker.com/compose/install/
安装命令如下: 
    
```
$ curl -L https://github.com/docker/compose/releases/download/1.11.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
$ docker-compose -v
```
    
或者通过 pip 安装

```
$ pip install -U docker-compose
```
## 二. 搭建Fabric 1.0.0  preview演示环境( solo共识方式，带自定义channel)

杨宝华的项目主页

https://github.com/yeasy/docker-compose-files/tree/master/hyperledger/1.0

### A.测试 Golang 编写的 ChainCode
#### 1. 安装操作系统和docker （略）
#### 2. 安装python pip（略）
#### 3. 安装 docker-compose 最新发布版本

```
pip install docker-compose 
```
        
#### 4.获取docker的 image,并更新镜像别名。
注意：这里一定要用tag来更新别名，要和docker-compose.yml 中的匹配
2017年02月16日，杨宝华mail确定：

```
The latest tag is auto-building by triggered from code change.

While those number tag (e.g., 0.8) is stable and manually set.
```

所以， 我们使用:
最新的版本的pull命令如下:

```
以root用户运行以下命令

ARCH=x86_64
BASE_VERSION=1.0.0-preview
PROJECT_VERSION=1.0.0-preview
IMG_VERSION=0.8.6
docker pull yeasy/hyperledger-fabric-base:$IMG_VERSION \
  && docker pull yeasy/hyperledger-fabric-peer:$IMG_VERSION \
  && docker pull yeasy/hyperledger-fabric-orderer:$IMG_VERSION \
  && docker pull yeasy/hyperledger-fabric-ca:$IMG_VERSION \
  && docker tag yeasy/hyperledger-fabric-peer:$IMG_VERSION hyperledger/fabric-peer \
  && docker tag yeasy/hyperledger-fabric-orderer:$IMG_VERSION hyperledger/fabric-orderer \
  && docker tag yeasy/hyperledger-fabric-ca:$IMG_VERSION hyperledger/fabric-ca \
  && docker tag yeasy/hyperledger-fabric-base:$IMG_VERSION hyperledger/fabric-baseimage \
  && docker tag yeasy/hyperledger-fabric-base:$IMG_VERSION hyperledger/fabric-ccenv:$ARCH-$BASE_VERSION \
  && docker tag yeasy/hyperledger-fabric-base:$IMG_VERSION hyperledger/fabric-baseos:$ARCH-$BASE_VERSION

```


#### 5.设置网络

```
docker network create fabric_noops
docker network create fabric_pbft
```

#### 6.启动 Fabric 1.0 

##### a. 下载 Compose 模板文件。

```
$ cd ~
git clone https://github.com/roamerxv/hyperledger-fabric.git
```

##### b. 进入hyperledger 1.0 模板目录

```
$ cd docker-compose-files/hyperledger/1.0
```
    
##### c. 查看包括若干模板文件，功能如下。

peers.yml: 包含 peer 节点的服务模板。
docker-compose.yml: 启动 1 个 最小化的环境，包括 1 个 peer 节点、1 个 Orderer 节点、1 个 CA 节点。


##### d. 部署和启动 Fabric 1.0

```
$ docker-compose -f docker-compose.yml up -d
```
    
####7. 查看容器信息
    应该有5个启动的容器，分别是
        1. fabric-peer0
        2. fabric-peer1
        3. fabric-peer2
        4. fabric-orderer
        5. fabric-ca
        
    
```
$ docker  ps 
# 或者
$ docker-compose ps 
```
#### 8.  建立一个channel 名字是myc1
进入任何一个peer容器内均可

```
docker exec -it fabric-peer2 bash

peer channel create  -o orderer:7050 -c myc1

#以下的环境变量设置，通过peer 命令中的-o 来指定了
#CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer:7050 


# 确认myc1.block文件产生了。说明channel的创世纪块建立成功
ls *.block 

```
#### 9. 把相应的peer(0,1,2)节点加入myc1

在建立channel 的容器里面，进行下面操作。

```
CORE_PEER_ADDRESS=peer0:7051 peer channel join -b myc1.block  -o orderer:7050

CORE_PEER_ADDRESS=peer1:7051 peer channel join -b myc1.block -o orderer:7050

CORE_PEER_ADDRESS=peer2:7051 peer channel join -b myc1.block -o orderer:7050
```

#### 10. 部署和实例化chaincode
* <font color="red">有几个peer需要运行这个chaincode，那就需要在这几个peer上都peer chaincode  install。
* 但是只需要在任意一个peer上peer chaincode instantiate 一次。
* 如果在其他peer上再做 instantiate ，就会出现错误。 
* 修改CORE_PEER_ADDRESS参数值即可指定在哪个peer上 install 和 instantiate。</font>

```
$ docker exec -it fabric-peer0 bash

# 部署一个chaincode
CORE_PEER_ADDRESS=peer0:7051 peer chaincode install  -C myc1 -n mycc -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02   -c '{}'  -v 1.1.0    -o orderer:7050

# 实例化一个chaincode
CORE_PEER_ADDRESS=peer0:7051 peer chaincode instantiate -C myc1 -n mycc -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Args":["init","a","100","b","200"]}'  -v 1.1.0 -o orderer:7050
```

<font color="red">注意：
*  在docker宿主机器上，使用docker ps 命令可以看到，在第一次指定一个peer（由CORE_PEER_ADDRESS指定），成功install 并且instantiate一个chaincode后，就会产生，并且up起来一个以这个peer和chaincode ，版本号为名字的容器。
*  接下来在其他peer上install这个相同的chaincode的时候，不会产生容器。（这个时候，由于已经有第一个peer进行了这个chaincode的instantiate，再在其他容器上instantiate 就会出错的，错误信息是chaincode已经存在）
*  当指定peer进行业务操作的时候，就会产生，并且up起来一个以这个指定的peer和chaincode ，版本号为名字的容器。</font>

```
docker ps 
dev-peer0-mycc-1.1.0 
```
   
#### 11.  查询chaincode
   部署完成后，等待几秒，或者查看log。确定部署完成,然后进行查询

```
CORE_PEER_ADDRESS=peer0:7051 peer chaincode query  -C myc1 -n mycc  -c '{"Args":["query","a"]}' -o orderer:7050

#返回结果是:
Query Result: 100
2017-03-15 08:05:17.429 UTC [main] main -> INFO 002 Exiting.....

#或者 

CORE_PEER_ADDRESS=peer0:7051 peer chaincode invoke  -C myc1  -n mycc -c '{"Args":["invoke","a","b","10"]}' peer chaincode invoke -n mycc -c '{"Args":["query","a"]}' -o orderer:7050
 
返回结果是:
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Invoke result: version:1 response:<status:200 message:"OK" payload:"100" > payload:"\n \...
[main] main -> INFO 002 Exiting.....

```
  

8. 调用chaincode
模拟转账业务

```
CORE_PEER_ADDRESS=peer0:7051 peer chaincode invoke  -C myc1  -n mycc -c '{"Args":["invoke","a","b","10"]}' -o orderer:7050
``` 
正确的返回内容:

```
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Invoke result: version:1 response:<status:200 message:"OK" > payload:... 
[main] main -> INFO 002 Exiting.....
注意最终结果状态正常 response:<status:200 message:"OK" >
```

过几秒后再调用查询业务，确认转账成功

```
CORE_PEER_ADDRESS=peer0:7051 peer chaincode query   -C myc1  -n mycc  -c '{"Args":["query","a"]}' -o orderer:7050
```

返回的正确内容,b账号里面多了转账的金额。


9. 查看日志
在docker server上执行如下命令:

```
$ cd ~/docker-compose-files/hyperledger/1.0
$ docker-compose logs -f
```

### B. 测试 java 编写的 ChainCode
#### 1. 增加一个 javaenv 的容器，以便于使用 java 的 CC 代码

```
docker pull hyperledger/fabric-javaenv:x86_64-1.0.0-alpha \
  && docker tag hyperledger/fabric-javaenv:x86_64-1.0.0-alpha hyperledger/fabric-javaenv:$ARCH-$BASE_VERSION  
```
#### 2.进入任意一个容器

```
docker exec -it fabric-peer2 bash

```
#### 3.部署和实例化一个 ChainCode

```
CORE_PEER_ADDRESS=peer0:7051 peer chaincode install -l java  -n mycc3 -p /go/src/github.com/hyperledger/fabric/examples/chaincode/java/SimpleSample   -c '{}'  -v 1.1.0    -o orderer:7050


CORE_PEER_ADDRESS=peer0:7051 peer chaincode instantiate -l java   -n mycc3 -p /go/src/github.com/hyperledger/fabric/examples/chaincode/java/SimpleSample   -c '{"Args":["init","roamer","100","dly","200"]}'  -v 1.1.0    -o orderer:7050
```
#### 4. 做一个转账

```
CORE_PEER_ADDRESS=peer0:7051 peer chaincode invoke  -l java  -n mycc3  -c  '{"Function":"transfer", "Args": ["roamer","dly","1"]}'  -v 1.1.0  -o orderer:7050 
```
#### 5.查询是否成功
```
#由于java 的 SimpleSample 里面没有查询功能，只能通过 cc 容器的日志查看来确定是否测试成功
docker logs -f  dev-peer0-mycc3-1.1.0
```
