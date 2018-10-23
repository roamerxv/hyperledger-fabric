# fabric 1.3.1  ，全手动部署到5台机器上.支持 kafka 模式的共识机制和 couchdb 存储，以及 fabric ca ， fabric explorer的使用。

参考文档
https://hyperledger-fabric.readthedocs.io/en/release-1.3/
https://www.lijiaocn.com/%E9%A1%B9%E7%9B%AE/2018/04/26/hyperledger-fabric-deploy.html
https://hyperledgercn.github.io/hyperledgerDocs/

系统环境：centos 7  64位
docker
docker-compose

## A. Fabric 1.3.1 的安装
### 一. 安装docker 

```bash
sudo yum -y remove docker docker-common container-selinux
sudo yum -y remove docker-selinux

sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum update

yum install docker-engine

systemctl enable docker

systemctl restart docker

```

###  二. 安装docker-compose

docker-compose是docker集群管理工具，可自定义一键启动多个docker container。
官网二进制发布:
https://github.com/docker/compose/releases
安装手册见网站 : 
https://docs.docker.com/compose/install/
安装命令如下: 
    
```bash
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

docker-compose -v
```
    


### 三.准备环境。

| IP | host |
| :-- | :-- | 
|192.168.188.110| cli.za.com|
|192.168.188.111|  kafka.za.com|
|192.168.188.112|  ca.za.com|
|192.168.188.113|  explorer.za.com|
|192.168.188.120 | orderer.za.com |
|192.168.188.221| peer0.org1.za.com|
|192.168.188.222| peer1.org1.za.com|
|192.168.188.223|  peer0.org2.za.com|
|192.168.188.224|  peer1.org2.za.com|


每台机器的 hostname 中都增加 ip 解析

```bash
vim /etc/hosts

192.168.188.110   cli.za.com
192.168.188.111   kafka.za.com
192.168.188.112   ca.za.com
192.168.188.113   explorer.za.com
192.168.188.120   orderer.za.com
192.168.188.221   peer0.org1.za.com
192.168.188.222   peer1.org1.za.com
192.168.188.223   peer0.org2.za.com
192.168.188.224   peer1.org2.za.com
```
工作目录是 /root/fabric
在/root/fabric目录下建立2个子目录
* /root/fabric/fabric-deploy 存放部署和配置内容
* /root/fabric/fabric-images 存放自己制作的 docker images

### 四.安装 kafka 和 zookeeper
我在这里使用 docker-compose 安装 zookeeper 和 kafka（3个 kafka 节点） 环境

配置文件存放在 
/Users/roamer/Documents/Docker/本地虚拟机/kafka 目录下

kafka 测试流程参考文档：
[kafka 的使用](mweblib://15357038240067)


### 五.下载 fabric 1.3.1

对应网站查看版本信息
https://nexus.hyperledger.org/#nexus-search;quick~fabric%201.3

#### 1. 下载文件自己安装

```bash
#登录 cli 主机
mkdir -p /root/fabric/fabric-deploy 
cd  ~/fabric/fabric-deploy
wget https://nexus.hyperledger.org/service/local/repositories/releases/content/org/hyperledger/fabric/hyperledger-fabric-1.3.1-stable/linux-amd64.1.3.1-stable-ce1bd72/hyperledger-fabric-1.3.1-stable-linux-amd64.1.3.1-stable-ce1bd72.tar.gz
```

#### 2. 用 md5sum 命令进行文件校验

#### 3. 解压fabric
```bash
tar -xvf hyperledger-fabric-1.3.1-stable-linux-amd64.1.3.1-stable-ce1bd72.tar.gz
```

#### 4. 理解 bin 目录和  config 目录下的文件

### 六. hyperledger 的证书准备

证书的准备方式有两种，一种用cryptogen命令生成，一种是通过fabric-ca服务生成。

#### 1.  通过cryptogen 来生成
创建一个配置文件crypto-config.yaml，这里配置了两个组织，org1和 org2的Template 的 Count是2，表示各自两个peer。
    
```yaml
vim crypto-config.yaml
    
#文件内容如下：
OrdererOrgs:
  - Name: Orderer
    Domain: za.com
    Specs:
      - Hostname: orderer
PeerOrgs:
  - Name: Org1
    Domain: org1.za.com
    Template:
      Count: 2
    Users:
      Count: 2
  - Name: Org2
    Domain: org2.za.com
    Template:
      Count: 2
    Users:
      Count: 2
```
        
生成证书, 所有的文件存放在 /root/fabric/fabric-deploy/certs 目录下

```bash
cd /root/fabric/fabric-deploy
./bin/cryptogen generate --config=crypto-config.yaml --output ./certs
```
    
#### 2. 通过 ca 服务来生成

在后续章节进行介绍
 
### 七. hyperledger fabric 中的Orderer 配置和安装文件的准备

#### 1. 建立一个存放orderer 配置文件的目录，用于以后复制到 orderer 主机上直接运行 orderer(支持 kafka)
    
```bash
cd /root/fabric/fabric-deploy
mkdir orderer.za.com
cd orderer.za.com
```
#### 2. 先将bin/orderer以及证书复制到orderer.za.com目录中。

```bash
cd /root/fabric/fabric-deploy
cp ./bin/orderer orderer.za.com
cp -rf ./certs/ordererOrganizations/za.com/orderers/orderer.za.com/* ./orderer.za.com/
```
    
#### 3. 然后准备orderer的配置文件orderer.za.com/orderer.yaml

```bash
vi /root/fabric/fabric-deploy/orderer.za.com/orderer.yaml
#内容如下
General:
    LedgerType: file
    ListenAddress: 0.0.0.0
    ListenPort: 7050
    TLS:
        Enabled: true
        PrivateKey: ./tls/server.key
        Certificate: ./tls/server.crt
        RootCAs:
          - ./tls/ca.crt
#        ClientAuthEnabled: false
#        ClientRootCAs:
    LogLevel: debug
    LogFormat: '%{color}%{time:2006-01-02 15:04:05.000 MST} [%{module}] %{shortfunc} -> %{level:.4s} %{id:03x}%{color:reset} %{message}'
#    GenesisMethod: provisional
    GenesisMethod: file
    GenesisProfile: SampleInsecureSolo
    GenesisFile: ./genesisblock
    LocalMSPDir: ./msp
    LocalMSPID: OrdererMSP
    Profile:
        Enabled: false
        Address: 0.0.0.0:6060
    BCCSP:
        Default: SW
        SW:
            Hash: SHA2
            Security: 256
            FileKeyStore:
                KeyStore:
FileLedger:
    Location:  /opt/fabric/orderer/data
    Prefix: hyperledger-fabric-ordererledger
RAMLedger:
    HistorySize: 1000
Kafka:
    Retry:
        ShortInterval: 5s
        ShortTotal: 10m
        LongInterval: 5m
        LongTotal: 12h
        NetworkTimeouts:
            DialTimeout: 10s
            ReadTimeout: 10s
            WriteTimeout: 10s
        Metadata:
            RetryBackoff: 250ms
            RetryMax: 3
        Producer:
            RetryBackoff: 100ms
            RetryMax: 3
        Consumer:
            RetryBackoff: 2s
    Verbose: false
    TLS:
      Enabled: false
      PrivateKey:
        #File: path/to/PrivateKey
      Certificate:
        #File: path/to/Certificate
      RootCAs:
        #File: path/to/RootCAs
    Version:
```
<font color="red">注意，orderer将被部署在目标机器（orderer.za.com）的/opt/fabric/orderer目录中，如果要部署在其它目录中，需要修改配置文件中路径。</font>

#### 4.  这里需要用到一个data目录，存放orderer的数据:
```bash
mkdir -p /root/fabric/fabric-deploy/orderer.za.com/data
```
    
#### 5. 创建一个启动 orderer 的批处理文件
    
```bash
vi  /root/fabric/fabric-deploy/orderer.za.com/startOrderer.sh
```    
    
在startOrderer.sh 中输入如下内容
    
```bash
#!/bin/bash
cd /opt/fabric/orderer
./orderer 2>&1 |tee log
```
    
修改成可以执行文件
    
```bash
chmod +x  /root/fabric/fabric-deploy/orderer.za.com/startOrderer.sh
```
    
### 八. hyperledger fabric 中的Peer 配置和安装文件的准备

建立4个存放peer 配置信息的目录

#### 1. 先设置 peer0.org1.za.com

```bash
mkdir -p  /root/fabric/fabric-deploy/peer0.org1.za.com
```
    
##### a. 复制 peer 执行文件和证书文件
    
```bash
cd /root/fabric/fabric-deploy
cp bin/peer peer0.org1.za.com/
cp -rf certs/peerOrganizations/org1.za.com/peers/peer0.org1.za.com/* peer0.org1.za.com/
```
<font color=red>
注意： 一定要复制对应的 peer 和 org 的目录。否则会出现各种错误
</font>
        
##### b. 生成 peer0.org1.za.com 的core.yaml 文件
        
<font color="red">
这里是基于 fabric 1.3.1版本修改的core.yaml 文件。不兼容fabric 1.2 版本
并且是使用 CouchDB 取代缺省的 LevelDB
</font>
    
```bash
vi /root/fabric/fabric-deploy/peer0.org1.za.com/core.yaml
#内容如下:
logging:
    level:      info
    cauthdsl:   warning
    gossip:     warning
    grpc:       error
    ledger:     info
    msp:        warning
    policies:   warning
    peer:
        gossip: warning
    
    format: '%{color}%{time:2006-01-02 15:04:05.000 MST} [%{module}] %{shortfunc} -> %{level:.4s} %{id:03x}%{color:reset} %{message}'
    
peer:
    
    id: peer0.org1.za.com
    
    networkId: dev
    
    listenAddress: 0.0.0.0:7051
    
    address: 0.0.0.0:7051
    
    addressAutoDetect: false
    
    gomaxprocs: -1
    
    keepalive:
        minInterval: 60s
        client:
            interval: 60s
            timeout: 20s
        deliveryClient:
            interval: 60s
            timeout: 20s
    
    gossip:
        bootstrap: peer0.org1.za.com:7051
    
        useLeaderElection: true
        orgLeader: false
    
        endpoint:
        maxBlockCountToStore: 100
        maxPropagationBurstLatency: 10ms
        maxPropagationBurstSize: 10
        propagateIterations: 1
        propagatePeerNum: 3
        pullInterval: 4s
        pullPeerNum: 3
        requestStateInfoInterval: 4s
        publishStateInfoInterval: 4s
        stateInfoRetentionInterval:
        publishCertPeriod: 10s
        skipBlockVerification: false
        dialTimeout: 3s
        connTimeout: 2s
        recvBuffSize: 20
        sendBuffSize: 200
        digestWaitTime: 1s
        requestWaitTime: 1500ms
        responseWaitTime: 2s
        aliveTimeInterval: 5s
        aliveExpirationTimeout: 25s
        reconnectInterval: 25s
        externalEndpoint:
        election:
            startupGracePeriod: 15s
            membershipSampleInterval: 1s
            leaderAliveThreshold: 10s
            leaderElectionDuration: 5s
        pvtData:
            pullRetryThreshold: 60s
            transientstoreMaxBlockRetention: 1000
            pushAckTimeout: 3s
            btlPullMargin: 10
            reconcileBatchSize: 10
            reconcileSleepInterval: 5m
    
    tls:
        enabled:  true
        clientAuthRequired: false
        cert:
            file: tls/server.crt
        key:
            file: tls/server.key
        rootcert:
            file: tls/ca.crt
        clientRootCAs:
            files:
              - tls/ca.crt
        clientKey:
            file:
        clientCert:
            file:
    
    authentication:
        timewindow: 15m
    
    fileSystemPath: /var/hyperledger/production
    
    BCCSP:
        Default: SW
        SW:
            Hash: SHA2
            Security: 256
            FileKeyStore:
                KeyStore:
        PKCS11:
            Library:
            Label:
            Pin:
            Hash:
            Security:
            FileKeyStore:
                KeyStore:
    
    mspConfigPath: msp
    
    localMspId: Org1MSP
    
    client:
        connTimeout: 3s
    
    deliveryclient:
        reconnectTotalTimeThreshold: 3600s
    
        connTimeout: 3s
    
        reConnectBackoffThreshold: 3600s
    
    localMspType: bccsp
    
    profile:
        enabled:     false
        listenAddress: 0.0.0.0:6060
    adminService:
    handlers:
        authFilters:
          -
            name: DefaultAuth
          -
            name: ExpirationCheck    # This filter checks identity x509 certificate expiration
        decorators:
          -
            name: DefaultDecorator
        endorsers:
          escc:
            name: DefaultEndorsement
            library:
        validators:
          vscc:
            name: DefaultValidation
            library:
    validatorPoolSize:
    discovery:
        enabled: true
        authCacheEnabled: true
        authCacheMaxSize: 1000
        authCachePurgeRetentionRatio: 0.75
        orgMembersAllowedAccess: false
    
vm:
    endpoint: unix:///var/run/docker.sock
    docker:
        tls:
            enabled: false
            ca:
                file: docker/ca.crt
            cert:
                file: docker/tls.crt
            key:
                file: docker/tls.key
        attachStdout: false
        hostConfig:
            NetworkMode: host
            Dns:
            LogConfig:
                Type: json-file
                Config:
                    max-size: "50m"
                    max-file: "5"
            Memory: 2147483648
    
    
chaincode:
    id:
        path:
        name:
    
    builder: $(DOCKER_NS)/fabric-ccenv:latest
    pull: false
    
    golang:
        runtime: $(BASE_DOCKER_NS)/fabric-baseos:$(ARCH)-$(BASE_VERSION)
        dynamicLink: false
    
    car:
        runtime: $(BASE_DOCKER_NS)/fabric-baseos:$(ARCH)-$(BASE_VERSION)
    
    java:
        runtime: $(DOCKER_NS)/fabric-javaenv:$(ARCH)-$(PROJECT_VERSION)
    
    node:
        runtime: $(BASE_DOCKER_NS)/fabric-baseimage:$(ARCH)-$(BASE_VERSION)
    startuptimeout: 300s
    
    executetimeout: 30s
    mode: net
    keepalive: 0
    system:
        +lifecycle: enable
        cscc: enable
        lscc: enable
        escc: enable
        vscc: enable
        qscc: enable
    systemPlugins:
    logging:
      level:  info
      shim:   warning
      format: '%{color}%{time:2006-01-02 15:04:05.000 MST} [%{module}] %{shortfunc} -> %{level:.4s} %{id:03x}%{color:reset} %{message}'
    
    
ledger:
    
  blockchain:
    
  state:
    stateDatabase: CouchDB     #goleveldb
    totalQueryLimit: 100000
    couchDBConfig:
       couchDBAddress: 127.0.0.1:5984
       username:    admin
       password:    password
       maxRetries: 3
       maxRetriesOnStartup: 10
       requestTimeout: 35s
       internalQueryLimit: 1000
       maxBatchUpdateSize: 1000
       warmIndexesAfterNBlocks: 1
       createGlobalChangesDB: false
    
  history:
    enableHistoryDatabase: true
    
    
metrics:
    enabled: false
    reporter: statsd
    interval: 1s
    statsdReporter:
          address: 0.0.0.0:8125
          flushInterval: 2s
          flushBytes: 1432
    promReporter:
          listenAddress: 0.0.0.0:8080

```
        
##### c. 建立 data 目录

```bash
mkdir -p /root/fabric/fabric-deploy/peer0.org1.za.com/data
```

##### d. 创建启动的批处理文件
     
 ```bah   
 vi  /root/fabric/fabric-deploy/peer0.org1.za.com/startPeer.sh
 ```
    
在文件中输入以下内容：
    
```bash
#!/bin/bash
cd /opt/fabric/peer
./peer node start 2>&1 |tee log
```
    
设置为可执行文件
    
```bash
chmod +x /root/fabric/fabric-deploy/peer0.org1.za.com/startPeer.sh
```
        
#### 2. 设置 peer1.org1.za.com

```bash
mkdir -p /root/fabric/fabric-deploy/peer1.org1.za.com
```
    
##### a.复制 peer 执行文件和证书文件
    
```bash
cd /root/fabric/fabric-deploy
cp bin/peer     peer1.org1.za.com/
cp -rf certs/peerOrganizations/org1.za.com/peers/peer1.org1.za.com/* peer1.org1.za.com/
    ```
        
##### b. 最后修改peer1.org1.za.com/core.yml，将其中的peer0.org1.za.com修改为peer1.org1.za.com，这里直接用sed命令替换:
        
```bash
cd /root/fabric/fabric-deploy
cp peer0.org1.za.com/core.yaml  peer1.org1.za.com
sed -i "s/peer0.org1.za.com/peer1.org1.za.com/g" peer1.org1.za.com/core.yaml
```
      
##### c.建立 data 目录

```bash
mkdir -p /root/fabric/fabric-deploy/peer1.org1.za.com/data
```

##### d.复制 staratPeer.sh 文件

```bash
cp /root/fabric/fabric-deploy/peer0.org1.za.com/startPeer.sh  peer1.org1.za.com/
```

#### 3.设置 peer0.org2.za.com

```bash
    mkdir -p /root/fabric/fabric-deploy/peer0.org2.za.com
```
    
##### a. 复制 peer 执行文件和证书文件
    
```bash
cd /root/fabric/fabric-deploy
cp bin/peer     peer0.org2.za.com/
cp -rf certs/peerOrganizations/org2.za.com/peers/peer0.org2.za.com/* peer0.org2.za.com/
```
    
##### b.最后修改peer0.org1.za.com/core.yml，将其中的peer0.org1.za.com修改为peer0.org2.za.com，这里直接用sed命令替换:
    
```bash
cd /root/fabric/fabric-deploy
cp peer0.org1.za.com/core.yaml  peer0.org2.za.com
sed -i "s/peer0.org1.za.com/peer0.org2.za.com/g" peer0.org2.za.com/core.yaml
```
      
##### c. 将配置文件中Org1MSP替换成Org2MSP:

```bash
sed -i "s/Org1MSP/Org2MSP/g" peer0.org2.za.com/core.yaml    
```
  
##### d.建立 data 目录

```bash
mkdir -p /root/fabric/fabric-deploy/peer0.org2.za.com/data
```

##### e.复制 staratPeer.sh 文件

```bash
cp /root/fabric/fabric-deploy/peer0.org1.za.com/startPeer.sh  peer0.org2.za.com/
```
    
        
#### 4. 设置 peer1.org2.za.com

```bash
mkdir -p /root/fabric/fabric-deploy/peer1.org2.za.com
```
    
##### a. 复制 peer 执行文件和证书文件
    
```bash
cd /root/fabric/fabric-deploy
cp bin/peer     peer1.org2.za.com/
cp -rf certs/peerOrganizations/org2.za.com/peers/peer1.org2.za.com/* peer1.org2.za.com/
```
        
##### b. 最后修改peer0.org1.za.com/core.yml，将其中的peer0.org1.za.com修改为peer1.org2.za.com，这里直接用sed命令替换:
        
```bash
cd /root/fabric/fabric-deploy
cp peer0.org1.za.com/core.yaml  peer1.org2.za.com
sed -i "s/peer0.org1.za.com/peer1.org2.za.com/g" peer1.org2.za.com/core.yaml
```
      
##### c. 将配置文件中Org1MSP替换成Org2MSP:

```bash
sed -i "s/Org1MSP/Org2MSP/g" peer1.org2.za.com/core.yaml    
```
      
##### d. 建立 data 目录

```bash
mkdir -p /root/fabric/fabric-deploy/peer1.org2.za.com/data
```

##### e. 复制 staratPeer.sh 文件

```bash
cp /root/fabric/fabric-deploy/peer0.org1.za.com/startPeer.sh  peer1.org2.za.com/
```

### 九. 准备hyperledger fabric 中的 order 和 peer 目标机器上的 配置文件部署

把准备好的 order 和 peer 上的配置文件复制到宿主机器上。
由于所有配置文件都是在 cli.za.com 机器上准备的，所以通过以下步骤复制到相应的主机上。目标地址按照配置文件都是存放在宿主机器/opt/fabric 目录下。

#### 1. 复制到 orderer.za.com 上
     
 ```bash
 # 在 orderer.za.com 机器上建立 /opt/fabric/orderer 目录
 mkdir -p /opt/fabric/orderer
 ```
 
 ```bash
 #回到 cli.za.com机器上，把 orderer的配置文件复制过去
 cd /root/fabric/fabric-deploy
 scp -r orderer.za.com/* root@orderer.za.com:/opt/fabric/orderer/
 ```
 
#### 2. 复制到peer0.org1.za.com

```bash
# 在 peer0.org1.za.com 机器上建立 /opt/fabric/peer 目录
mkdir -p /opt/fabric/peer
```
 
```bash
#回到 cli.za.com机器上，把 peer0.org1.za.com的配置文件复制过去
cd /root/fabric/fabric-deploy
scp -r peer0.org1.za.com/* root@peer0.org1.za.com:/opt/fabric/peer/
```

#### 3. 复制到peer1.org1.za.com
    
```bash
# 在 peer1.org1.za.com 机器上建立 /opt/fabric/peer 目录
 mkdir -p /opt/fabric/peer
```
 
```bash
 #回到 cli.za.com机器上，把 peer1.org1.za.com 的配置文件复制过去
 cd /root/fabric/fabric-deploy
 scp -r peer1.org1.za.com/* root@peer1.org1.za.com:/opt/fabric/peer/
```
 
#### 4. 复制到peer0.org2.za.com

```bash
# 在 peer0.org2.za.com 机器上建立 /opt/fabric/peer 目录
mkdir -p /opt/fabric/peer
```
 
```bash
#回到 cli.za.com机器上，把 peer0.org2.za.com的配置文件复制过去
cd /root/fabric/fabric-deploy
scp -r peer0.org2.za.com/* root@peer0.org2.za.com:/opt/fabric/peer/
```
    
#### 5. 复制到peer1.org2.za.com

```bash
# 在 peer1.org2.za.com 机器上建立 /opt/fabric/peer 目录
mkdir -p /opt/fabric/peer
```
 
```bash
#回到 cli.za.com机器上，把 peer1.org2.za.com的配置文件复制过去
cd /root/fabric/fabric-deploy
scp -r peer1.org2.za.com/* root@peer1.org2.za.com:/opt/fabric/peer/
```

### 十. 准备创世纪区块 genesisblock(kafka 模式)

#### 1.  在 cli 机器的 /root/fabric/fabric-deploy/目录下，准备创世纪块的生成配置文件 configtx.yaml
    
```yaml
vi /root/fabric/fabric-deploy/configtx.yaml
    
#文件内容如下：
Organizations:
    - &OrdererOrg
        Name: OrdererOrg
        ID: OrdererMSP
        MSPDir: ./certs/ordererOrganizations/za.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('OrdererMSP.admin')"
    - &Org1
        Name: Org1MSP
        ID: Org1MSP
        MSPDir: ./certs/peerOrganizations/org1.za.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org1MSP.admin', 'Org1MSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('Org1MSP.admin', 'Org1MSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('Org1MSP.admin')"
        AnchorPeers:
            - Host: peer0.org1.za.com
              Port: 7051
    - &Org2
        Name: Org2MSP
        ID: Org2MSP
        MSPDir: ./certs/peerOrganizations/org2.za.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org2MSP.admin', 'Org2MSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('Org2MSP.admin', 'Org2MSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('Org2MSP.admin')"
        AnchorPeers:
            - Host: peer0.org2.za.com
              Port: 7051
    
Capabilities:
    Channel: &ChannelCapabilities
        V1_3: true
    Orderer: &OrdererCapabilities
        V1_1: true
    Application: &ApplicationCapabilities
        V1_3: true
        V1_2: false
        V1_1: false
    
Application: &ApplicationDefaults
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    Capabilities:
        <<: *ApplicationCapabilities    
    
Orderer: &OrdererDefaults
    OrdererType: kafka
    Addresses:
        - orderer.za.com:7050
    BatchTimeout: 2s
    BatchSize:
        MaxMessageCount: 10
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 512 KB
    Kafka:
        Brokers:
            - kafka.za.com:9092       # 可以填入多个kafka节点的地址
            - kafka.za.com:9093
            - kafka.za.com:9094
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"
    Capabilities:
        <<: *OrdererCapabilities
    
Channel: &ChannelDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    Capabilities:
        <<: *ChannelCapabilities
    
Profiles:
    TwoOrgsOrdererGenesis:
        <<: *ChannelDefaults
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - *OrdererOrg
        Consortiums:
            SampleConsortium:
                Organizations:
                    - *Org1
                    - *Org2
    TwoOrgsChannel:
        Consortium: SampleConsortium
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *Org1
                - *Org2
```
`踩坑`： 
此版本是 fabric 1.3.1版本下使用的配置文件。不向下兼容（不能用在1.2和之前的版本）。

#### 2. 生成创世纪区块
    
```bash
cd /root/fabric/fabric-deploy
./bin/configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./genesisblock -channelID genesis
```
生成创世纪区块文件 genesisblock ，并且指定创世区块的 channel id 是 genesis
    
#### 3. 然后把区块文件 genesisblock 复制到 oderer.za.com机器上
    
```bash
#登录到 cli 主机
cd /root/fabric/fabric-deploy
scp ./genesisblock  root@orderer.za.com:/opt/fabric/orderer
```
    
### 十一. 启动 orderer 和 peer
#### 1. 启动 orderer

```bash
# 进入 orderer.za.com 主机的 /opt/fabric/orderer 目录,以后台进程方式启动orderer
nohup ./startOrderer.sh &
```
    
启动成功后，可以去任意一台 kafka 服务器上的控制台查看 topic 列表，是否有一个 genesis 的 channel。

```bash
/opt/kafka_2.11-1.1.1/bin/kafka-topics.sh --zookeeper 192.168.188.111:2181 --list
```
  
#### 2.  在4个 peer 上安装 couchDB
    
详细介绍查看 ：
 [fabric peer 节点使用 CouchDB 来替换 LevelDB.](mweblib://15355039052312)
    
#### 3. 启动4个 peer
    
```bash
#分别进入4个 peer 主机的 /opt/fabric/peer 目录
#以后台进程方式启动 peer
nohup ./startPeer.sh &
```
    
#### 4. 把 peer 主机上的 peer 进程注册成开机启动
    
在/etc/init.d 目录下建立一个  autoRunPeer.sh 文件。并且修改成可执行权限。
文件内容如下：
    
```bash
#!/bin/sh
#chkconfig: 2345 80 90 
#表示在2/3/4/5运行级别启动，启动序号(S80)，关闭序号(K90)； 
/usr/bin/nohup /opt/fabric/peer/startPeer.sh &
```
    
添加脚本到开机自动启动项目中
    
```bash
chkconfig --add autoRunPeer.sh
chkconfig autoRunPeer.sh on
```
  
#### 5. 把 orderer 主机上的 orderer 进程注册成开机启动
    
在/etc/init.d 目录下建立一个  autoRunOrderer.sh 文件。并且修改成可执行权限。
文件内容如下：
    
```bash
#!/bin/sh
#chkconfig: 2345 80 90 
#表示在2/3/4/5运行级别启动，启动序号(S80)，关闭序号(K90)； 
/usr/bin/nohup /opt/fabric/orderer/startOrderer.sh &
```
    
添加脚本到开机自动启动项目中
    
```bash
chkconfig --add autoRunOrderer.sh
chkconfig autoRunOrderer.sh on
```

### 十二. 用户账号创建
#### 1. 在 cli 机器上建立存放用户账号信息的目录

```bash
cd  /root/fabric/fabric-deploy
mkdir users 
cd users
```
    
#### 2. 创立 org1的Admin 用户信息（对应到 peer0.org1.za.com 的节点）
    
##### a. 创建用于保存 org1 的 Admin 用户信息的目录
    
```bash
cd /root/fabric/fabric-deploy/users
mkdir Admin@org1.za.com
cd  Admin@org1.za.com
```
        
##### b. 复制Admin@org1.za.com用户的证书
    
```bash
cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org1.za.com/users/Admin@org1.za.com/* /root/fabric/fabric-deploy/users/Admin@org1.za.com/
    
```
        
##### c. 复制peer0.org1.za.com的配置文件(对应到 peer0.org1.za.com 的节点)
    
```bash
cp /root/fabric/fabric-deploy/peer0.org1.za.com/core.yaml  /root/fabric/fabric-deploy/users/Admin@org1.za.com/
```
        
##### d. 创建测试脚本(peer.sh)
    
```bash
#!/bin/bash
cd "/root/fabric/fabric-deploy/users/Admin@org1.za.com"
PATH=`pwd`/../../bin:$PATH
export FABRIC_CFG_PATH=`pwd`
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
export CORE_PEER_TLS_KEY_FILE=./tls/client.key
export CORE_PEER_MSPCONFIGPATH=./msp
export CORE_PEER_ADDRESS=peer0.org1.za.com:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
export CORE_PEER_ID=peer0.org1.za.com
export CORE_LOGGING_LEVEL=DEBUG
peer $*
```
注意：
其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer0.org1.za.com 节点对应
        
##### e. 运行 peer.sh 来查看节点 peer0.org1.aclor.com 的状态
    
```bash
./peer.sh node status
```
![-w1288](media/15382874126951/15383298724232.jpg)


#### 3. 创立 org1的 User1 用户信息  （对应到 peer1.org1.za.com 的节点）
    
##### a. 创建保存 org1 的 User1 用户信息的目录（对应到 peer1.org1.za.com）

<font color="red"> 
其实是 <font size=6>Admin </font>的用户证书，如果用的是User1的证书，在 peer node status 的时候，会出现错误：
Error trying to connect to local peer: rpc error: code = Unknown desc = access denied
    
</font>
    
```bash
cd /root/fabric/fabric-deploy/users
mkdir User1@org1.za.com
cd  User1@org1.za.com
```
    
##### b. 复制User1@org1.za.com用户的证书
    
```bash
cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org1.za.com/users/Admin@org1.za.com/* /root/fabric/fabric-deploy/users/User1@org1.za.com/
    
```
    
##### c. 复制peer1.org1.za.com的配置文件（对应到 peer1.org1.za.com）
    
```bash
cp /root/fabric/fabric-deploy/peer1.org1.za.com/core.yaml  /root/fabric/fabric-deploy/users/User1@org1.za.com/
```
    
##### d. 创建测试脚本(peer.sh)
    
```bash
#!/bin/bash
cd "/root/fabric/fabric-deploy/users/User1@org1.za.com"
PATH=`pwd`/../../bin:$PATH
export FABRIC_CFG_PATH=`pwd`
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
export CORE_PEER_TLS_KEY_FILE=./tls/client.key
export CORE_PEER_MSPCONFIGPATH=./msp
export CORE_PEER_ADDRESS=peer1.org1.za.com:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
export CORE_PEER_ID=peer1.org1.za.com
export CORE_LOGGING_LEVEL=DEBUG
peer $*
```
注意：
    其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer1.org1.za.com 节点对应
    
##### e. 运行 peer.sh 来查看节点 peer1.org1.za.com 的状态
    
```bash
./peer.sh node status
```
    
#### 4. 创立 org2的Admin 用户信息（对应到 peer0.org2.za.com 的节点）
    
##### a. 创建保存 org2 的 Admin 用户信息的目录
    
```bash
cd /root/fabric/fabric-deploy/users
mkdir Admin@org2.za.com
cd  Admin@org2.za.com
```
        
##### b. 复制Admin@org2.za.com用户的证书
    
```bash
cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org2.za.com/users/Admin@org2.za.com/* /root/fabric/fabric-deploy/users/Admin@org2.za.com/
    
```
        
##### c. 复制peer0@org2.za.com的配置文件(对应到 peer0.org2.za.com 的节点)
    
```bash
cp /root/fabric/fabric-deploy/peer0.org2.za.com/core.yaml  /root/fabric/fabric-deploy/users/Admin@org2.za.com/
```
        
##### d. 创建测试脚本(peer.sh)
    
```bash
#!/bin/bash
cd "/root/fabric/fabric-deploy/users/Admin@org2.za.com"
PATH=`pwd`/../../bin:$PATH
export FABRIC_CFG_PATH=`pwd`
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
export CORE_PEER_TLS_KEY_FILE=./tls/client.key
export CORE_PEER_MSPCONFIGPATH=./msp
export CORE_PEER_ADDRESS=peer0.org2.za.com:7051
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
export CORE_PEER_ID=peer0.org2.za.com
export CORE_LOGGING_LEVEL=DEBUG
peer $*
```
注意：
    其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer0.org1.za.com 节点对应
    
##### e. 运行 peer.sh 来查看节点 peer0.org2.za.com 的状态
    
```bash
./peer.sh node status
```
    
#### 5. 创立 org2的User1用户信息（对应到 peer1.org2.za.com 的节点）

<font color="red"> 
其实是 <font size=6>Admin </font>的用户证书，如果用的是User1的证书，在 peer node status 的时候，会出现错误：
Error trying to connect to local peer: rpc error: code = Unknown desc = access denied
</font>
  
##### a. 创建保存 org2 的 User1 用户信息的目录
    
```bash
cd /root/fabric/fabric-deploy/users
mkdir User1@org2.za.com
cd  User1@org2.za.com
```
        
##### b. 复制Admin@org2.za.com用户的证书
    
```bash
cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org2.za.com/users/Admin@org2.za.com/* /root/fabric/fabric-deploy/users/User1@org2.za.com/
    
```
        
##### c. 复制peer0@org2.za.com的配置文件(对应到 peer0.org2.za.com 的节点)
    
```bash
cp /root/fabric/fabric-deploy/peer1.org2.za.com/core.yaml  /root/fabric/fabric-deploy/users/User1@org2.za.com/
```
        
##### d. 创建测试脚本(peer.sh)
        
```bash
#!/bin/bash
cd "/root/fabric/fabric-deploy/users/User1@org2.za.com"
PATH=`pwd`/../../bin:$PATH
export FABRIC_CFG_PATH=`pwd`
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
export CORE_PEER_TLS_KEY_FILE=./tls/client.key
export CORE_PEER_MSPCONFIGPATH=./msp
export CORE_PEER_ADDRESS=peer1.org2.za.com:7051
export CORE_PEER_LOCALMSPID=Org2MSP
export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
export CORE_PEER_ID=peer1.org2.za.com
export CORE_LOGGING_LEVEL=DEBUG
peer $*
```
注意：
    其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer0.org1.za.com 节点对应
        
##### e. 运行 peer.sh 来查看节点 peer0.org2.za.com 的状态
    
```bash
./peer.sh node status
```

        
### 十三. channel 的准备和创建

<font color="red">
踩坑：channel ID 不能含有大写字母（myTestChannel , myChannel 这种命名是不行的，在创建 channel 的时候，会报错）
initializing configtx manager failed: bad channel ID: channel ID 'myTestChannel' contains illegal characters
</font>
    
#### 1. 准备channel 文件。用configtxgen生成channel文件。 
configtxgen 命令会去当前目录下的configtx.yaml（也可以通过FABRIC_CFG_PATH 指定） 中的profiles 部分下的和 -profile 参数对应的部分的内容，生成出一个 -outputCreateChannelTx  指定的输出文件

```bash
 cd /root/fabric/fabric-deploy/
./bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx mychannel.tx -channelID mychannel
    
```
    
### 十四. 创建 channel

#### 1. 在Admin@org1.za.com目录中执行下面的命令：
    
```bash
cd  /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh channel create -o orderer.za.com:7050 -c mychannel -f /root/fabric/fabric-deploy/mychannel.tx  -t 60s --tls true --cafile  /root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/tlsca/tlsca.za.com-cert.pem

```
 
执行完成后，会生成一个mychannel.block文件. 
<font color=red>
这个文件非常重要!所有加入到这个 channel 里面的 peer，都需要用到这个文件
</font>
    
####  2.将mychannel.block复制一份到User1@org1.za.com 和 Admin@org2.za.com、User1@org2.za.com中备用
    
```bash
\cp -f /root/fabric/fabric-deploy/users/Admin@org1.za.com/mychannel.block  /root/fabric/fabric-deploy/users/User1@org1.za.com/    
\cp -f /root/fabric/fabric-deploy/users/Admin@org1.za.com/mychannel.block  /root/fabric/fabric-deploy/users/Admin@org2.za.com/
\cp -f /root/fabric/fabric-deploy/users/Admin@org1.za.com/mychannel.block  /root/fabric/fabric-deploy/users/User1@org2.za.com/    
``` 

### 十五.把 4个 peer加入到 channel 中

#### 1. 把peer0.org1.za.com 加入到 channle 中

```bash
cd  /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh channel join -b mychannel.block
#控制台返回成功后，可以用下面命令来查看
./peer.sh channel list
```

#### 2. 把peer1.org1.za.com 加入到 channle 中
    
```bash
cd  /root/fabric/fabric-deploy/users/User1@org1.za.com #这个其实还是org1.za.com 的 Admin 用户
./peer.sh channel join -b mychannel.block
#控制台返回成功后，可以用下面命令来查看
./peer.sh channel list
```
    
#### 3. 把peer0.org2.za.com 加入到 channle 中
    
```bash
cd  /root/fabric/fabric-deploy/users/Admin@org2.za.com
./peer.sh channel join -b mychannel.block
#控制台返回成功后，可以用下面命令来查看
./peer.sh channel list
```
    
#### 4. 把peer1.org2.za.com 加入到 channle 中
    
```bash
cd  /root/fabric/fabric-deploy/users/User1@org2.za.com #这个其实还是org2.za.com 的 Admin 用户
./peer.sh channel join -b mychannel.block
#控制台返回成功后，可以用下面命令来查看
./peer.sh channel list
```


### 十六.设置锚点 peer .

需要每个组织指定一个anchor peer，anchor peer是组织用来接收orderer下发的区块的peer。
锚点的设置 已经在 configtx.yaml 文件中配置，不需要在进行 peer channel update 操作了。

    
### 十七. go 版本的 chaincode 的安装和部署（在 cli 主机上操作）

#### 1. 安装 go 环境

go 的下载官网 

https://golang.org/dl/

以 root 用户安装
    
```bash
wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz

tar -xvf  go1.10.3.linux-amd64.tar.gz

mv ./go  /usr/local

#修改 /etc/profile，增加 如下2行内容
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
    
#使得环境变量生效
source /etc/profile
    
#确定 go 的安装成功和版本信息
go version 
    
#查看 go 的环境
go env
```
    
#### 2. 拉取 demo 的 chaincode
    
`这个需要先安装 gcc 组件`

```bash
cd ~
go get github.com/roamerxv/chaincode/fabric/examples/go/demo
```
    
完成后，生成一个~/go 目录。下面有 src 和bin 目录。/root/go/src/github.com 目录下有个fabric 和 roamerxv 这2个目录。
    
        
#### 3. chaincode 的安装

```bash
cd /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

```
由于 peer.sh 中指定了CORE_PEER_ADDRESS=peer0.org1.za.com:7051 ，所以，这个安装其实是把 chaincode 文件复制到 peer0.org1.za.com 这台机器的 /var/hyperledger/production/chaincodes/ 目录下. 文件名是 demo.0.0.1. 

而 /var/hyperledger/production/chaincodes/ 这个路径是由 core.yaml 里面的 peer.fileSystemPath 这个属性指定的。
    
![-w399](media/15382874126951/15383353467012.jpg)

 
 ```bash
 #同时，可以在 cli 上，通过以下命令查看 peer 上的 chaincode 信息
 cd /root/fabric/fabric-deploy/users/Admin@org1.za.com
 ./peer.sh chaincode list   --installed
 ```
 ![-w1124](media/15382874126951/15383354233467.jpg)


<font color="red">
注意: 这个安装需要在涉及到的所有 peer 上进行一遍,包括另外的组织 org2. 而且一定要用 admin用户来安装。
</font>
    
```bash
    
#进入另外3个目录，再次安装 chaincode 到对应的 peer 上
#这个是 安装到 peer1.org1.za.com
cd  /root/fabric/fabric-deploy/users/User1@org1.za.com
./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

    
#这个是 安装到 peer0.org2.za.com
cd  /root/fabric/fabric-deploy/users/Admin@org2.za.com
./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo


#这个是 安装到 peer1.org2.za.com
cd  /root/fabric/fabric-deploy/users/User1@org2.za.com
./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

    
```
    
#### 4. chaincode 的初始化

合约安装之后，需要且只需要进行一次初始化，只能由签署合约的用户进行初始化,并且所有的 peer 上的 docker 服务已经启动。谁签署了 chaincode，谁来进行实例化。

```bash
cd  /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh chaincode instantiate -o orderer.za.com:7050 --tls true --cafile  /root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/tlsca/tlsca.za.com-cert.pem -C mychannel -n demo -v 0.0.1 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')"
```
第一次进行合约初始化的时候的会比较慢，因为peer 上需要创建、启动容器。
    
#### 5. chaincode的调用

```bsh
cd  /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh chaincode invoke -o orderer.za.com:7050  --tls true --cafile /root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/tlsca/tlsca.za.com-cert.pem  -C mychannel -n demo  -c '{"Args":["write","key1","key1value中文isabc"]}'
```
<font color="red">
chaincode 的调用，可以调用任意一台安装了这个 chaincode 的peer。这个时候被调用的 peer 上会启动相应的 chaincode 的 docker。
</font>
    
进行查询操作时，不需要指定orderer，例如：
    
```bash
cd /root/fabric/fabric-deploy/users/User1@org1.za.com
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'
```
    
#### 6. chaincode 的更新
    
新的合约也需要在每个peer上单独安装。
    
```bash
#安装到peer0.org1.za.com
cd /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh chaincode install  -n demo -v 0.0.2 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

    
#安装到peer1.org1.za.com
cd /root/fabric/fabric-deploy/users/User1@org1.za.com
./peer.sh chaincode install  -n demo -v 0.0.2 -p github.com/roamerxv/chaincode/fabric/examples/go/demo
    
#安装到peer0.org2.za.com
cd /root/fabric/fabric-deploy/users/Admin@org2.za.com
./peer.sh chaincode install  -n demo -v 0.0.2 -p github.com/roamerxv/chaincode/fabric/examples/go/demo
    
 #安装到peer1.org2.za.com
cd /root/fabric/fabric-deploy/users/User1@org2.za.com
./peer.sh chaincode install  -n demo -v 0.0.2 -p github.com/roamerxv/chaincode/fabric/examples/go/demo
```
    
更新的合约不需要初始化，需要进行更新操作。
    
```bash
cd /home/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh chaincode upgrade -o orderer.za.com:7050 --tls true --cafile  /root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/tlsca/tlsca.za.com-cert.pem  -C mychannel -n demo -v 0.0.2 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')"
```
    
 更新后，直接调用新合约。 `调用的时候，不需要指定版本号，直接会调用最新版本的 CC`
 
 ```bash
  ./peer.sh chaincode invoke -o orderer.za.com:7050  --tls true --cafile /root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/tlsca/tlsca.za.com-cert.pem  -C mychannel -n demo  -c '{"Args":["write","key1","徐泽宇&徐芷攸"]}'
   ./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'
 ```
    
#### 7. 查询key的历史记录

```bash
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["history","key1"]}'
```

### 十八. java 版本的 chaincode 的安装和部署（在 cli 主机上操作）（未完成，待修改。。。）

#### 1. 在 cli 主机上拉取 java chaincode 的代码, 需要安装 `java` 和 `gradle`

```bash
cd /root
git clone  https://github.com/hyperledger/fabric-chaincode-java
#安装 java 和 gradle(略过)
```
    
#### 2. gradle 编译 chaincode 的支持包(`Build java shim jars (proto and shim jars) and install them to local maven repository.`),好像需要 翻墙（gradle 指定 proxy的方法是在 gradle 命令后面跟-D参数：  -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016）。参考文档是 fabric-chaincode-java目录下的 FAQ.md
    
    
```bash
cd /root/fabric-chaincode-java/

gradle clean build install -x test -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016
    
```

#### 3.编译 chaincode
    
```bash
cd /root/fabric-chaincode-java/fabric-chaincode-example-gradle
gradle clean build shadowJar -x test -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016
#生成的 jar 文件位于    ./build/libs  目录下的 chaincode.jar
    
cd /root/fabric-chaincode-java
gradle buildImage -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016
```

#### 4.安装 chaincode

```bash
cd /root/fabric/fabric-deploy/users/Admin@org1.za.com
./peer.sh chaincode install -l java  -n mycc -v 1.0.0 -p /root/fabric-chaincode-java/fabric-chaincode-example-gradle
```
    
#### 5.  实例化chaincode 

```bash
./peer.sh chaincode instantiate -o orderer.za.com:7050 --tls true --cafile /root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/tlsca/tlsca.za.com-cert.pem -C mychannel -n mycc -v 1.0.0 -c  '{"Args":["init","roamer","100","dly","200"]}' -P "OR('Org1MSP.member','Org2MSP.member')"

```

`踩坑`：
* 下载 image  ： hyperledger/fabric-javaenv:amd64-1.3.0 不存在。
    解决办法: 修改 peer 上的 core.yaml 文件中的chaincode-java-runtime 部分，直接指定
    
```yaml
java:
    #runtime: $(DOCKER_NS)/fabric-javaenv:$(ARCH)-$(PROJECT_VERSION)
    runtime: $(DOCKER_NS)/fabric-javaenv:$(ARCH)-1.3.0-rc1
```
    
kill 掉原来的 peer 进程，再启动 peer 。在 cli 上重新 instance CC 。peer 节点上会自动 pull image。如果不重启 peer，core.yaml 不会起作用,一直报同样的错误。
    

## B. Fabric explorer 的安装和使用

[hyperledger explorer(0.3.7) 安装](mweblib://15366371522047)

## C. Fabric CA的安装和使用

参考文档 
https://www.lijiaocn.com/%E9%A1%B9%E7%9B%AE/2018/05/04/fabric-ca-example.html
https://www.lijiaocn.com/%E9%A1%B9%E7%9B%AE/2018/04/27/hyperledger-fabric-ca-usage.html

### 一. 在 ca.za.com 主机上安装 Fabric-ca 1.3 

#### 1. 安装 go 环境
    
```bash
cd /root
wget https://dl.google.com/go/go1.10.4.linux-amd64.tar.gz
tar -xvf  go1.10.4.linux-amd64.tar.gz
mv ./go  /usr/local
    
#修改 /etc/profile，增加 如下2行内容
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
export GOPATH=/root
#使得环境变量生效
source /etc/profile
#确定 go 的安装成功和版本信息
go version 
#查看 go 的环境
go env
```
    
#### 2. fabirc-ca的下载和编译
        
#####  a. 通过源码编译的方式
        
```bash
yum install libtool   libtool-ltdl-devel
    
cd /root
mkdir -p /root/src/github.com/hyperledger/
cd /root/src/github.com/hyperledger/
git clone https://github.com/hyperledger/fabric-ca.git
cd /root/src/github.com/hyperledger/fabric-ca
git checkout release-1.3

make fabric-ca-server
make fabric-ca-client
ls ./bin/
# 发现有以下2个执行文件
fabric-ca-client  fabric-ca-server
    
```
            
#####  b. 直接下载的方式(`只能下载到 fabric-ca client`)
```bash
cd \root
wget https://nexus.hyperledger.org/service/local/repositories/releases/content/org/hyperledger/fabric-ca/hyperledger-fabric-ca-1.3.0-stable/linux-amd64.1.3.0-stable-4f6586e/hyperledger-fabric-ca-1.3.0-stable-linux-amd64.1.3.0-stable-4f6586e.tar.gz
```
        
####  3.启动 fabric server

#####  a. 为了支持 `删除联盟`和`删除用户`的需求，用下面的方式启动
缺省监听端口 7054
   
```bash
mkdir -p /root/fabric-ca-files/server
   
fabric-ca-server start -b admin:password --cfg.affiliations.allowremove  --cfg.identities.allowremove -H /root/fabric-ca-files/server &
```
   
#####  b. 配置成随系统启动 fabric-ca-server    
    
```bash   
vi /etc/init.d/autoRunFabric-ca-server.sh
```
    
在文件中加入下面内容
    
```sh
#!/bin/sh
#chkconfig: 2345 80 90 
#表示在2/3/4/5运行级别启动，启动序号(S80)，关闭序号(K90)； 
/usr/local/bin/fabric-ca-server start -b admin:password --cfg.affiliations.allowremove  --cfg.identities.allowremove  -H /root/fabric-ca-files/server &
```
    
配置成随系统启动
    
```bash
chmod +x /etc/init.d/autoRunFabric-ca-server.sh
chkconfig --add autoRunFabric-ca-server.sh
chkconfig autoRunFabric-ca-server.sh on
```
    
`理解/root/fabric-ca-files/admin下的文件。`
    
* msp ：包含keystore，CA服务器的私钥
* ca-cert.pem ：CA服务端的证书
* fabric-ca-server.db ：CA默认使用的嵌入型数据库 SQLite
* fabric-ca-server-config.yaml ：CA服务端的配置文件

        
####  4. 生成fabric ca 的管理员 (admin)证书和秘钥的流程    
        
#####  a.生成fabric-ca admin的凭证，用-H参数指定client目录：

```bash
mkdir -p /root/fabric-ca-files/admin
fabric-ca-client enroll -u http://admin:password@localhost:7054 -H /root/fabric-ca-files/admin
```
    
也可以用环境变量FABRIC_CA_CLIENT_HOME指定了client的工作目录，生成的用户凭证将存放在这个目录中。

#####  b. 查看默认的联盟
   
上面的启动方式默认会创建两个组织：
可以通过下面命令进行查看
    
```bash
$ fabric-ca-client  -H /root/fabric-ca-files/admin  affiliation list
    
affiliation: .
   affiliation: org2
      affiliation: org2.department1
   affiliation: org1
      affiliation: org1.department1
      affiliation: org1.department2
```
#####  c. 删除联盟

```bash
fabric-ca-client -H  /root/fabric-ca-files/admin  affiliation remove --force  org1
fabric-ca-client -H  /root/fabric-ca-files/admin  affiliation remove --force  org2
```
       
#####  d. 创建自己定义的联盟

```bash
fabric-ca-client  -H  /root/fabric-ca-files/admin  affiliation add com 
fabric-ca-client  -H  /root/fabric-ca-files/admin  affiliation add com.za
fabric-ca-client  -H  /root/fabric-ca-files/admin  affiliation add com.za.org1
fabric-ca-client  -H  /root/fabric-ca-files/admin  affiliation add com.za.org2
```
        
#####  e. 查看刚刚建立的联盟

```bash
$ fabric-ca-client  -H /root/fabric-ca-files/admin  affiliation list
```

#####  f. 为各个组织生成凭证（MSP），就是从Fabric-CA中，读取出用来签署用户的根证书等
        
```bash
mkdir -p  /root/fabric-ca-files/Organizations/za.com/msp
```
    
######  1)为 org1.za.com 获取证书
    
```bash
fabric-ca-client getcacert -M /root/fabric-ca-files/Organizations/org1.za.com/msp
```

######  2)为 org2.za.com 获取证书
    
```bash
fabric-ca-client getcacert -M /root/fabric-ca-files/Organizations/org2.za.com/msp
```
    
这里是用getcacert为每个组织准备需要的ca文件，在生成创始块的时候会用到。

`在1.3.0版本的fabric-ca中，只会生成用户在操作区块链的时候用到的证书和密钥，不会生成用来加密grpc通信的证书。`

######  3)这里复用之前在 cli 主机上用 cryptogen 生成的tls证书，需要将验证tls证书的ca添加到msp目录中，如下：
    
```bash
scp -r root@cli.za.com:/root/fabric/fabric-deploy/certs/ordererOrganizations/za.com/msp/tlscacerts /root/fabric-ca-files/Organizations/za.com/msp/
scp -r root@cli.za.com:/root/fabric/fabric-deploy/certs/peerOrganizations/org1.za.com/msp/tlscacerts/  /root/fabric-ca-files/Organizations/org1.za.com/msp/
scp -r root@cli.za.com:/root/fabric/fabric-deploy/certs/peerOrganizations/org2.za.com/msp/tlscacerts/  /root/fabric-ca-files/Organizations/org2.za.com/msp/
```
    
如果在你的环境中，各个组件域名的证书，是由第三方CA签署的，就将第三方CA的根证书添加到msp/tlscacerts目录中。

组织的msp目录中，包含都是CA根证书，分别是TLS加密的根证书，和用于身份验证的根证书。另外还需要admin用户的证书，后面的操作中会添加。

#####  g.  证书查看命令
    
```bash
openssl x509 -in /root/fabric-ca-files/admin/msp/cacerts/localhost-7054.pem  -text
```

#####  h.  注册联盟中的各个管理员Admin
       
######  1) 注册za.com的管理员 Admin@za.com
            
~~·`用命令行的方式进行注册（命令行太长，用第二种方式）`~~

```bash
fabric-ca-client register -H /root/fabric-ca-files/admin \
    --id.name Admin@za.com  \
    --id.type client  \
    --id.
    --id.affiliation "com.za"  \
    --id.attrs  \
        '"hf.Registrar.Roles=client,orderer,peer,user",\
        "hf.Registrar.DelegateRoles=client,orderer,peer,user",\
        "hf.Registrar.Attributes=*",\
        "hf.GenCRL=true",\
        "hf.Revoker=true",\
        "hf.AffiliationMgr=true",\
        "hf.IntermediateCA=true",\
        "role=admin:ecert"'
    
```
            
`使用配置文件的方式进行注册(主要的使用方法)`
                    
1.  修改 /root/fabric-ca-files/admin/fabric-ca-client-config.yaml 中的 id 部分
        
    ```bash
    vim /root/fabric-ca-files/admin/fabric-ca-client-config.yaml
    ```
    修改内容为
        
    ```bash
    id:
      name: Admin@za.com
      type: client
      affiliation: com.za
      maxenrollments: 0
      attributes:
        - name: hf.Registrar.Roles
          value: client,orderer,peer,user
        - name: hf.Registrar.DelegateRoles
          value: client,orderer,peer,user
        - name: hf.Registrar.Attributes
          value: "*"
        - name: hf.GenCRL
          value: true
        - name: hf.Revoker
          value: true
        - name: hf.AffiliationMgr
          value: true
        - name: hf.IntermediateCA
          value: true
        - name: role
          value: admin
          ecert: true
    ```
    注意最后一行role属性，是我们自定义的属性，对于自定义的属性，要设置certs，在配置文件中需要单独设置ecert属性为true或者false。如果在命令行中，添加后缀:ecert表示true.
    其它配置的含义是用户名为Admin@za.com，类型是client，它能够管理com.za.*下的用户，如下:
                
    ```
    --id.name  Admin@za.com                           //用户名
    --id.type client                                       //类型为client
    --id.affiliation "com.za"                         //权利访问
    hf.Registrar.Roles=client,orderer,peer,user            //能够管理的用户类型
    hf.Registrar.DelegateRoles=client,orderer,peer,user    //可以授权给子用户管理的用户类型
    hf.Registrar.Attributes=*                              //可以为子用户设置所有属性
    hf.GenCRL=true                                         //可以生成撤销证书列表
    hf.Revoker=true                                        //可以撤销用户
    hf.AffiliationMgr=true                                 //能够管理联盟
    hf.IntermediateCA=true                                 //可以作为中间CA
    role=admin:ecert                                       //自定义属性
    ```
            
    所有hr 开头的属性，非常重要，是 fabric ca 的内置属性。具体内容可以查看 官方文档的描述。https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html
    
2.  修改完成后，用如下命令注册用户
           
       ```bash
       fabric-ca-client register -H /root/fabric-ca-files/admin --id.secret=password
       ```
       如果不用 `--id.secret指定密码`，会自动生成密码
           
3. 注册完成之后，还需要对这个用户生成凭证。
    
    a. 用 命令来确定，刚才注册的用户已经成功生成.
        
    ```bash
    fabric-ca-client identity  list  -H /root/fabric-ca-files/admin    
    ```
    可以查看当前的用户列表，以及每个用户的详细信息。
            
    b. 生成凭证
    
    ```bash
    fabric-ca-client enroll -u http://Admin@za.com:password@localhost:7054  -H /root/fabric-ca-files/Organizations/za.com/admin
    ```
    -H 参数指定Admin@za.com 的用户凭证的存放目录。在这个目录下参数了这样的目录和文件
    ![-w699](media/15382874126951/15398372078328.jpg)   

    
    c.  这时候可以用Admin@za.com的身份查看联盟信息：
            
    ```bash
    fabric-ca-client affiliation list -H /root/fabric-ca-files/Organizations/za.com/admin
    ```     
    ```bash
    #显示结果
    affiliation: com
       affiliation: com.za
          affiliation: com.za.org1
          affiliation: com.za.org2
    ```
    
4. 如果是管理员权限，还需要复制到/msp/admincerts/目录下。
最后将Admin@za.com的证书复制到za.com/msp/admincerts/中, `只有这样，才能具备管理员权限。`
            
    ```bash
    mkdir /root/fabric-ca-files/Organizations/za.com/msp/admincerts/
    cp /root/fabric-ca-files/Organizations/za.com/admin/msp/signcerts/cert.pem  /root/fabric-ca-files/Organizations/za.com/msp/admincerts/
    ```
                
######  2) 注册org1.za.com的管理员 Admin@org1.za.com

1. 修改 /root/fabric-ca-files/admin/fabric-ca-client-config.yaml 中的 id 部分。
`可以使用其他的fabric-ca-client-config.yaml文件，没有必须使用这个ca 的 admin 下面的fabric-ca-client-config.yaml文件的必然要求`

    ```bash
    vim /root/fabric-ca-files/admin/fabric-ca-client-config.yaml
    ```
    修改内容为
        
    ```bash
    id:
      name: Admin@org1.za.com
      type: client
      affiliation: com.za.org1
      maxenrollments: 0
      attributes:
        - name: hf.Registrar.Roles
          value: client,orderer,peer,user
        - name: hf.Registrar.DelegateRoles
          value: client,orderer,peer,user
        - name: hf.Registrar.Attributes
          value: "*"
        - name: hf.GenCRL
          value: true
        - name: hf.Revoker
          value: true
        - name: hf.AffiliationMgr
          value: true
        - name: hf.IntermediateCA
          value: true
        - name: role
          value: admin
          ecert: true
    ```
    
2. 修改注册Admin@org1.za.com 用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/admin --id.secret=password   
    ```
    
3. 生成凭证
 
    ```bash
    fabric-ca-client enroll -u http://Admin@org1.za.com:password@localhost:7054  -H /root/fabric-ca-files/Organizations/org1.za.com/admin
    ``` 
        
4. 用这个凭证查看联盟
    
    ```bash
    fabric-ca-client affiliation list -H /root/fabric-ca-files/Organizations/org1.za.com/admin
    ```
    `注意：`
    这个时候，只能看见 org1.za.com 的联盟信息。和 Admin@za.com 的权限是不同的
    
5. 把凭证复制到 org1.za.com的msp/admincerts 目录下
    
    ```bash
    mkdir -p /root/fabric-ca-files/Organizations/org1.za.com/msp/admincerts
    cp /root/fabric-ca-files/Organizations/org1.za.com/admin/msp/signcerts/cert.pem  /root/fabric-ca-files/Organizations/org1.za.com/msp/admincerts/
    ```

######  3) 注册org2.za.com的管理员 Admin@org2.za.com

1. 修改 /root/fabric-ca-files/admin/fabric-ca-client-config.yaml 中的 id 部分。
`可以使用其他的fabric-ca-client-config.yaml文件，没有必须使用这个ca 的 admin 下面的fabric-ca-client-config.yaml文件的必然要求`

    ```bash
    vim /root/fabric-ca-files/admin/fabric-ca-client-config.yaml
    ```
    修改内容为
        
    ```bash
    id:
      name: Admin@org2.za.com
      type: client
      affiliation: com.za.org2
      maxenrollments: 0
      attributes:
        - name: hf.Registrar.Roles
          value: client,orderer,peer,user
        - name: hf.Registrar.DelegateRoles
          value: client,orderer,peer,user
        - name: hf.Registrar.Attributes
          value: "*"
        - name: hf.GenCRL
          value: true
        - name: hf.Revoker
          value: true
        - name: hf.AffiliationMgr
          value: true
        - name: hf.IntermediateCA
          value: true
        - name: role
          value: admin
          ecert: true
    ```
    
2. 修改注册Admin@org1.za.com 用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/admin --id.secret=password   
    ```
    
3. 生成凭证
 
    ```bash
    fabric-ca-client enroll -u http://Admin@org2.za.com:password@localhost:7054  -H /root/fabric-ca-files/Organizations/org2.za.com/admin
    ``` 
        
4. 用这个凭证查看联盟
    
    ```bash
    fabric-ca-client affiliation list -H /root/fabric-ca-files/Organizations/org2.za.com/admin
    ```
    `注意：`
    这个时候，只能看见 org2.za.com 的联盟信息。和 Admin@za.com , Admin@org1.za.com 的权限是不同的
    
5. 把凭证复制到 org2.za.com的msp/admincerts 目录下
    
    ```bash
    mkdir -p /root/fabric-ca-files/Organizations/org2.za.com/msp/admincerts
    cp /root/fabric-ca-files/Organizations/org2.za.com/admin/msp/signcerts/cert.pem  /root/fabric-ca-files/Organizations/org2.za.com/msp/admincerts/
    ```
    
#####  i.  使用各个组织中的 Admin 来创建其他账号
######  1). 用 Admin@za.com 来创建 orderer.za.com 的账号

1. 修改 /root/fabric-ca-files/Organizations/za.com/admin/fabric-ca-client-config.yaml文件的配置

    ```bash
    vi /root/fabric-ca-files/Organizations/za.com/admin/fabric-ca-client-config.yaml
    ```
    配置 id 的部分 用于orderer@alcom.com 
    ```bash
    id:
      name: orderer.za.com
      type: orderer
      affiliation: com.za
      maxenrollments: 0
      attributes:
        - name: role
          value: orderer
          ecert: true
    ```
    
2. 注册 orderer@za.com 的用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/Organizations/za.com/admin --id.secret=password
    ```

3. 生成证书文件

    ```bash
    fabric-ca-client enroll -u http://orderer.za.com:password@localhost:7054 -H /root/fabric-ca-files/Organizations/za.com/orderer
    ```

4. 将Admin@za.com的证书复制到orderer 的admincerts下

    ```bash
    # 建立 orderer 下的 admincerts 目录
    mkdir /root/fabric-ca-files/Organizations/za.com/orderer/msp/admincerts
    # 复制 Admin@za.com 的证书到  orderer 的 msp/admincerts 目录下
    cp /root/fabric-ca-files/Organizations/za.com/admin/msp/signcerts/cert.pem /root/fabric-ca-files/Organizations/za.com/orderer/msp/admincerts/

    ```

 `注意:`
 为什么要这么做？！！！
 
######  2). 用 Admin@org1.za.com 来创建 peer0.org1.za.com 的账号

1. 修改 /root/fabric-ca-files/Organizations/org1.za.com/admin/fabric-ca-client-config.yaml文件的配置

    ```bash
    vi /root/fabric-ca-files/Organizations/org1.za.com/admin/fabric-ca-client-config.yaml
    ```
        
    配置 id 的部分 用于orderer@alcom.com 
        
    ```bash
    id:
      name: peer0.org1.za.com
      type: peer
      affiliation: com.za.org1
      maxenrollments: 0
      attributes:
        - name: role
          value: peer
          ecert: true
    ```
    
2. 注册 orderer@za.com 的用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/Organizations/org1.za.com/admin --id.secret=password
    ```

3. 生成证书文件

    ```bash
    fabric-ca-client enroll -u http://peer0.org1.za.com:password@localhost:7054 -H /root/fabric-ca-files/Organizations/org1.za.com/peer0
    ```

4. 将Admin@org1.za.com的证书复制到 org1\peer0 的admincerts下

    ```bash
    # 建立 peer0 下的 admincerts 目录
    mkdir /root/fabric-ca-files/Organizations/org1.za.com/peer0/msp/admincerts
    # 复制 Admin@org1.za.com 的证书到  peer0 的 msp/admincerts 目录下
    cp /root/fabric-ca-files/Organizations/org1.za.com/admin/msp/signcerts/cert.pem /root/fabric-ca-files/Organizations/org1.za.com/peer0/msp/admincerts/

    ```

######  3). 用 Admin@org1.za.com 来创建 peer1.org1.za.com 的账号

1. 修改 /root/fabric-ca-files/Organizations/org1.za.com/admin/fabric-ca-client-config.yaml文件的配置

    ```bash
    vi /root/fabric-ca-files/Organizations/org1.za.com/admin/fabric-ca-client-config.yaml
    ```
        
    配置 id 的部分 用于orderer@alcom.com 
        
    ```bash
    id:
      name: peer1.org1.za.com
      type: peer
      affiliation: com.za.org1
      maxenrollments: 0
      attributes:
        - name: role
          value: peer
          ecert: true
    ```
    
2. 注册 orderer@za.com 的用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/Organizations/org1.za.com/admin --id.secret=password
    ```

3. 生成证书文件

    ```bash
    fabric-ca-client enroll -u http://peer1.org1.za.com:password@localhost:7054 -H /root/fabric-ca-files/Organizations/org1.za.com/peer1
    ```

4. 将Admin@org1.za.com的证书复制到 org1\peer1 的admincerts下

    ```bash
    # 建立 peer1 下的 admincerts 目录
    mkdir /root/fabric-ca-files/Organizations/org1.za.com/peer1/msp/admincerts
    # 复制 Admin@org1.za.com 的证书到  peer1 的 msp/admincerts 目录下
    cp /root/fabric-ca-files/Organizations/org1.za.com/admin/msp/signcerts/cert.pem /root/fabric-ca-files/Organizations/org1.za.com/peer1/msp/admincerts/

    ```

######  4). 用 Admin@org2.za.com 来创建 peer0.org2.za.com 的账号

1. 修改 /root/fabric-ca-files/Organizations/org2.za.com/admin/fabric-ca-client-config.yaml文件的配置

    ```bash
    vi /root/fabric-ca-files/Organizations/org2.za.com/admin/fabric-ca-client-config.yaml
    ```
        
    配置 id 的部分 用于orderer@alcom.com 
        
    ```bash
    id:
      name: peer0.org2.za.com
      type: peer
      affiliation: com.za.org2
      maxenrollments: 0
      attributes:
        - name: role
          value: peer
          ecert: true
    ```
    
2. 注册 orderer@za.com 的用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/Organizations/org2.za.com/admin --id.secret=password
    ```

3. 生成证书文件

    ```bash
    fabric-ca-client enroll -u http://peer0.org2.za.com:password@localhost:7054 -H /root/fabric-ca-files/Organizations/org2.za.com/peer0
    ```

4. 将Admin@org2.za.com的证书复制到 org2\peer0 的admincerts下

    ```bash
    # 建立 peer0 下的 admincerts 目录
    mkdir /root/fabric-ca-files/Organizations/org2.za.com/peer0/msp/admincerts
    # 复制 Admin@org2.za.com 的证书到  peer0 的 msp/admincerts 目录下
    cp /root/fabric-ca-files/Organizations/org2.za.com/admin/msp/signcerts/cert.pem /root/fabric-ca-files/Organizations/org2.za.com/peer0/msp/admincerts/

    ```

######  5). 用 Admin@org2.za.com 来创建 peer1.org2.za.com 的账号

1. 修改 /root/fabric-ca-files/Organizations/org2.za.com/admin/fabric-ca-client-config.yaml文件的配置

    ```bash
    vi /root/fabric-ca-files/Organizations/org2.za.com/admin/fabric-ca-client-config.yaml
    ```
        
    配置 id 的部分 用于orderer@alcom.com 
        
    ```bash
    id:
      name: peer1.org2.za.com
      type: peer
      affiliation: com.za.org2
      maxenrollments: 0
      attributes:
        - name: role
          value: peer
          ecert: true
    ```
    
2. 注册 orderer@za.com 的用户

    ```bash
    fabric-ca-client register -H /root/fabric-ca-files/Organizations/org2.za.com/admin --id.secret=password
    ```

3. 生成证书文件

    ```bash
    fabric-ca-client enroll -u http://peer1.org2.za.com:password@localhost:7054 -H /root/fabric-ca-files/Organizations/org2.za.com/peer1
    ```

4. 将Admin@org2.za.com的证书复制到 org2\pee1 的admincerts下

    ```bash
    # 建立 peer1 下的 admincerts 目录
    mkdir /root/fabric-ca-files/Organizations/org2.za.com/peer1/msp/admincerts
    # 复制 Admin@org2.za.com 的证书到  peer1 的 msp/admincerts 目录下
    cp /root/fabric-ca-files/Organizations/org2.za.com/admin/msp/signcerts/cert.pem /root/fabric-ca-files/Organizations/org2.za.com/peer1/msp/admincerts/

    ```



###  二. 一些常用的Fabric ca 命令

#### 1. 查看证书信息

通过 openssh 命令来查看证书信息
        
```bash
openssl x509 -in  /root/fabric-ca-files/Organizations/za.com/msp/admincerts/cert.pem  -text
```

#### 2. 查看identity 的命令

```bash
fabric-ca-client identity  list  -H /root/fabric-ca-files/admin
```    

#### 3. 删除identity 的命令
    
```bash
fabric-ca-client  identity remove Admin@za.com -H /root/fabric-ca-files/admin
```

#### 4. 查询 创世区块的命令
    
```bash
configtxgen -inspectBlock genesisblock | jq
```
把查询信息转换成 json。需要安装  jq
    
###  三.  未完！待续...
