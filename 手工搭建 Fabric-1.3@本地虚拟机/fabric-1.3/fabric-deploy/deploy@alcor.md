# fabric 1.3.1  ，全手动部署到5台机器上.支持 kafka 模式的共识机制和 couchdb 存储
参考文档
https://hyperledger-fabric.readthedocs.io/en/release-1.3/
https://www.lijiaocn.com/%E9%A1%B9%E7%9B%AE/2018/04/26/hyperledger-fabric-deploy.html
https://hyperledgercn.github.io/hyperledgerDocs/

系统环境：centos 7  64位
docker
docker-compose

## 1. 安装docker 

```bash
sudo yum -y remove docker docker-common container-selinux
sudo yum -y remove docker-selinux

sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum update

yum install docker-engine

systemctl enable docker

systemctl restart docker

```

## 2.  安装docker-compose

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
    


## 3.准备环境。

| IP | host |
| :-- | :-- | 
|192.168.188.110| cli.alcor.com|
|192.168.188.111|  kafka.alcor.com|
|192.168.188.112|  ca.alcor.com|
|192.168.188.113|  explorer.alcor.com|
|192.168.188.120 | orderer.alcor.com |
|192.168.188.221| peer0.org1.alcor.com|
|192.168.188.222| peer1.org1.alcor.com|
|192.168.188.223|  peer0.org2.alcor.com|
|192.168.188.224|  peer1.org2.alcor.com|


每台机器的 hostname 中都增加 ip 解析

```bash
vim /etc/hosts

192.168.188.110   cli.alcor.com
192.168.188.111   kafka.alcor.com
192.168.188.112   ca.alcor.com
192.168.188.113   explorer.alcor.com
192.168.188.120   orderer.alcor.com
192.168.188.221   peer0.org1.alcor.com
192.168.188.222   peer1.org1.alcor.com
192.168.188.223   peer0.org2.alcor.com
192.168.188.224   peer1.org2.alcor.com
```
工作目录是 /root/fabric
在/root/fabric目录下建立2个子目录
* /root/fabric/fabric-deploy 存放部署和配置内容
* /root/fabric/fabric-images 存放自己制作的 docker images

## 4.安装 kafka 和 zookeeper
我在这里使用 docker-compose 安装 zookeeper 和 kafka（3个 kafka 节点） 环境

配置文件存放在 
/Users/roamer/Documents/Docker/本地虚拟机/kafka 目录下

kafka 测试流程参考文档：
[kafka 的使用](mweblib://15357038240067)


## 5.下载 fabric 1.3.1

对应网站查看版本信息
https://nexus.hyperledger.org/#nexus-search;quick~fabric%201.3

1. 下载文件自己安装

    ```bash
    #登录 cli 主机
    mkdir -p /root/fabric/fabric-deploy 
    cd  ~/fabric/fabric-deploy
    wget https://nexus.hyperledger.org/service/local/repositories/releases/content/org/hyperledger/fabric/hyperledger-fabric-1.3.1-stable/linux-amd64.1.3.1-stable-ce1bd72/hyperledger-fabric-1.3.1-stable-linux-amd64.1.3.1-stable-ce1bd72.tar.gz
    
    ```

2. 用 md5sum 命令进行文件校验

3. 解压fabric
    ```bash
    tar -xvf hyperledger-fabric-1.3.1-stable-linux-amd64.1.3.1-stable-ce1bd72.tar.gz
    ```

4. 理解 bin 目录和  config 目录下的文件

## 6. hyperledger 的证书准备

证书的准备方式有两种，一种用cryptogen命令生成，一种是通过fabric-ca服务生成。

1.  通过cryptogen 来生成
    * 创建一个配置文件crypto-config.yaml，这里配置了两个组织，org1和 org2的Template 的 Count是2，表示各自两个peer。
    
        ```yaml
        vim crypto-config.yaml
        
        #文件内容如下：
        OrdererOrgs:
          - Name: Orderer
            Domain: alcor.com
            Specs:
              - Hostname: orderer
        PeerOrgs:
          - Name: Org1
            Domain: org1.alcor.com
            Template:
              Count: 2
            Users:
              Count: 2
          - Name: Org2
            Domain: org2.alcor.com
            Template:
              Count: 2
            Users:
              Count: 2
        ```
        
    *  生成证书, 所有的文件存放在 /root/fabric/fabric-deploy/certs 目录下

        ```bash
        cd /root/fabric/fabric-deploy
        ./bin/cryptogen generate --config=crypto-config.yaml --output ./certs
        ```
    
1. 通过 ca 服务来生成
    在后续章节进行介绍
 
## 7. hyperledger fabric 中的Orderer 配置和安装文件的准备

1. 建立一个存放orderer 配置文件的目录，用于以后复制到 orderer 主机上直接运行 orderer(支持 kafka)
    
    ```bash
    cd /root/fabric/fabric-deploy
    mkdir orderer.alcor.com
    cd orderer.alcor.com
    ```
2. 先将bin/orderer以及证书复制到orderer.alcor.com目录中。

    ```bash
    cd /root/fabric/fabric-deploy
    cp ./bin/orderer orderer.alcor.com
    cp -rf ./certs/ordererOrganizations/alcor.com/orderers/orderer.alcor.com/* ./orderer.alcor.com/
    ```
    
1. 然后准备orderer的配置文件orderer.alcor.com/orderer.yaml

    ```bash
    vi /root/fabric/fabric-deploy/orderer.alcor.com/orderer.yaml
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
    <font color="red">
    注意，orderer将被部署在目标机器（orderer.alcor.com）的/opt/fabric/orderer目录中，如果要部署在其它目录中，需要修改配置文件中路径。</font>

1.  这里需要用到一个data目录，存放orderer的数据:
    ```bash
    mkdir -p /root/fabric/fabric-deploy/orderer.alcor.com/data
    ```
    
1. 创建一个启动 orderer 的批处理文件
    
    ```bash
    vi  /root/fabric/fabric-deploy/orderer.alcor.com/startOrderer.sh
    ```    
    在startOrderer.sh 中输入如下内容
    
    ```bash
    #!/bin/bash
    cd /opt/fabric/orderer
    ./orderer 2>&1 |tee log
    ```
    
    修改成可以执行文件
    
    ```bash
    chmod +x  /root/fabric/fabric-deploy/orderer.alcor.com/startOrderer.sh
    ```
    
## 8. hyperledger fabric 中的Peer 配置和安装文件的准备

建立4个存放peer 配置信息的目录

1. <font  size="+2">先设置 peer0.org1.alcor.com</font>

    ```bash
    mkdir -p  /root/fabric/fabric-deploy/peer0.org1.alcor.com
    ```
    
    1. 复制 peer 执行文件和证书文件
    
        ```bash
        cd /root/fabric/fabric-deploy
        cp bin/peer peer0.org1.alcor.com/
        cp -rf certs/peerOrganizations/org1.alcor.com/peers/peer0.org1.alcor.com/* peer0.org1.alcor.com/
        ```
        <font color=red>
        注意： 一定要复制对应的 peer 和 org 的目录。否则会出现各种错误
        </font>
        
    1. 生成 peer0.org1.alcor.com 的core.yaml 文件
        
        <font color="red">
        这里是基于 fabric 1.3.1版本修改的core.yaml 文件。不兼容fabric 1.2 版本
        并且是使用 CouchDB 取代缺省的 LevelDB
        </font>
    
        ```bash
        vi /root/fabric/fabric-deploy/peer0.org1.alcor.com/core.yaml
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
        
            id: peer0.org1.alcor.com
        
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
                bootstrap: peer0.org1.alcor.com:7051
        
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
        
    3. 建立 data 目录

        ```bash
        mkdir -p /root/fabric/fabric-deploy/peer0.org1.alcor.com/data
        ```

    4. 创建启动的批处理文件
     
         ```bah   
         vi  /root/fabric/fabric-deploy/peer0.org1.alcor.com/startPeer.sh
         ```
        
        在文件中输入以下内容：
        
        ```bash
        #!/bin/bash
        cd /opt/fabric/peer
        ./peer node start 2>&1 |tee log
        ```
        
        设置为可执行文件
        
        ```bash
        chmod +x /root/fabric/fabric-deploy/peer0.org1.alcor.com/startPeer.sh
        ```
        
2.  <font color="green"  size="+2">设置 peer1.org1.alcor.com</font>

     ```bash
        mkdir -p /root/fabric/fabric-deploy/peer1.org1.alcor.com
     ```
    
    1. 复制 peer 执行文件和证书文件
    
        ```bash
        cd /root/fabric/fabric-deploy
        cp bin/peer     peer1.org1.alcor.com/
        cp -rf certs/peerOrganizations/org1.alcor.com/peers/peer1.org1.alcor.com/* peer1.org1.alcor.com/
        ```
        
   2. 最后修改peer1.org1.alcor.com/core.yml，将其中的peer0.org1.alcor.com修改为peer1.org1.alcor.com，这里直接用sed命令替换:
        
      ```bash
      cd /root/fabric/fabric-deploy
      cp peer0.org1.alcor.com/core.yaml  peer1.org1.alcor.com
      sed -i "s/peer0.org1.alcor.com/peer1.org1.alcor.com/g" peer1.org1.alcor.com/core.yaml
      ```
      
  3. 建立 data 目录

        ```bash
        mkdir -p /root/fabric/fabric-deploy/peer1.org1.alcor.com/data
        ```

 4. 复制 staratPeer.sh 文件

        ```bash
        cp /root/fabric/fabric-deploy/peer0.org1.alcor.com/startPeer.sh  peer1.org1.alcor.com/
        ```

1. <font color="yellow"  size="+2"> 设置 peer0.org2.alcor.com</font>

    ```bash
        mkdir -p /root/fabric/fabric-deploy/peer0.org2.alcor.com
    ```
    
    1. 复制 peer 执行文件和证书文件
    
        ```bash
        cd /root/fabric/fabric-deploy
        cp bin/peer     peer0.org2.alcor.com/
        cp -rf certs/peerOrganizations/org2.alcor.com/peers/peer0.org2.alcor.com/* peer0.org2.alcor.com/
        ```
        
   2. 最后修改peer0.org1.alcor.com/core.yml，将其中的peer0.org1.alcor.com修改为peer0.org2.alcor.com，这里直接用sed命令替换:
        
      ```bash
      cd /root/fabric/fabric-deploy
      cp peer0.org1.alcor.com/core.yaml  peer0.org2.alcor.com
      sed -i "s/peer0.org1.alcor.com/peer0.org2.alcor.com/g" peer0.org2.alcor.com/core.yaml
      ```
      
  3. 将配置文件中Org1MSP替换成Org2MSP:

        ```bash
        sed -i "s/Org1MSP/Org2MSP/g" peer0.org2.alcor.com/core.yaml    
        ```
      
  4. 建立 data 目录

        ```bash
        mkdir -p /root/fabric/fabric-deploy/peer0.org2.alcor.com/data
        ```

 5. 复制 staratPeer.sh 文件

        ```bash
        cp /root/fabric/fabric-deploy/peer0.org1.alcor.com/startPeer.sh  peer0.org2.alcor.com/
        ```
        
        
4. <font color="blue"  size="+2"> 设置 peer1.org2.alcor.com</font>

    ```bash
    mkdir -p /root/fabric/fabric-deploy/peer1.org2.alcor.com
    ```
    
    1. 复制 peer 执行文件和证书文件
    
        ```bash
        cd /root/fabric/fabric-deploy
        cp bin/peer     peer1.org2.alcor.com/
        cp -rf certs/peerOrganizations/org2.alcor.com/peers/peer1.org2.alcor.com/* peer1.org2.alcor.com/
        ```
        
   2. 最后修改peer0.org1.alcor.com/core.yml，将其中的peer0.org1.alcor.com修改为peer1.org2.alcor.com，这里直接用sed命令替换:
        
      ```bash
      cd /root/fabric/fabric-deploy
      cp peer0.org1.alcor.com/core.yaml  peer1.org2.alcor.com
      sed -i "s/peer0.org1.alcor.com/peer1.org2.alcor.com/g" peer1.org2.alcor.com/core.yaml
      ```
      
  3. 将配置文件中Org1MSP替换成Org2MSP:

        ```bash
        sed -i "s/Org1MSP/Org2MSP/g" peer1.org2.alcor.com/core.yaml    
        ```
      
  4. 建立 data 目录

        ```bash
        mkdir -p /root/fabric/fabric-deploy/peer1.org2.alcor.com/data
        ```

 4. 复制 staratPeer.sh 文件

        ```bash
        cp /root/fabric/fabric-deploy/peer0.org1.alcor.com/startPeer.sh  peer1.org2.alcor.com/
        ```

## 9. hyperledger fabric 中的 order 和 peer 目标机器上的 配置文件部署

把准备好的 order 和 peer 上的配置文件复制到宿主机器上。
由于所有配置文件都是在 cli.alcor.com 机器上准备的，所以通过以下步骤复制到相应的主机上。目标地址按照配置文件都是存放在宿主机器/opt/fabric 目录下。

 1. 复制到 orderer.alcor.com 上
     
     ```bash
     # 在 orderer.alcor.com 机器上建立 /opt/fabric/orderer 目录
     mkdir -p /opt/fabric/orderer
     ```
     
     ```bash
     #回到 cli.alcor.com机器上，把 orderer的配置文件复制过去
     cd /root/fabric/fabric-deploy
     scp -r orderer.alcor.com/* root@orderer.alcor.com:/opt/fabric/orderer/
     ```
     
 2. 复制到peer0.org1.alcor.com

     ```bash
     # 在 peer0.org1.alcor.com 机器上建立 /opt/fabric/peer 目录
     mkdir -p /opt/fabric/peer
     ```
     
     ```bash
     #回到 cli.alcor.com机器上，把 peer0.org1.alcor.com的配置文件复制过去
     cd /root/fabric/fabric-deploy
     scp -r peer0.org1.alcor.com/* root@peer0.org1.alcor.com:/opt/fabric/peer/
     ```

 3. 复制到peer1.org1.alcor.com
    
    ```bash
    # 在 peer1.org1.alcor.com 机器上建立 /opt/fabric/peer 目录
     mkdir -p /opt/fabric/peer
    ```
     
    ```bash
     #回到 cli.alcor.com机器上，把 peer1.org1.alcor.com 的配置文件复制过去
     cd /root/fabric/fabric-deploy
     scp -r peer1.org1.alcor.com/* root@peer1.org1.alcor.com:/opt/fabric/peer/
    ```
 
 4. 复制到peer0.org2.alcor.com

    ```bash
    # 在 peer0.org2.alcor.com 机器上建立 /opt/fabric/peer 目录
    mkdir -p /opt/fabric/peer
    ```
     
    ```bash
    #回到 cli.alcor.com机器上，把 peer0.org2.alcor.com的配置文件复制过去
    cd /root/fabric/fabric-deploy
    scp -r peer0.org2.alcor.com/* root@peer0.org2.alcor.com:/opt/fabric/peer/
    ```
    
5. 复制到peer1.org2.alcor.com

    ```bash
    # 在 peer1.org2.alcor.com 机器上建立 /opt/fabric/peer 目录
    mkdir -p /opt/fabric/peer
    ```
     
    ```bash
    #回到 cli.alcor.com机器上，把 peer1.org2.alcor.com的配置文件复制过去
    cd /root/fabric/fabric-deploy
    scp -r peer1.org2.alcor.com/* root@peer1.org2.alcor.com:/opt/fabric/peer/
    ```

## 10. 准备创世纪区块 genesisblock(kafka 模式)

1. 在 cli 机器的 /root/fabric/fabric-deploy/目录下，准备创世纪块的生成配置文件 configtx.yaml
    
    ```yaml
    vi /root/fabric/fabric-deploy/configtx.yaml
    
    #文件内容如下：
    Organizations:
        - &OrdererOrg
            Name: OrdererOrg
            ID: OrdererMSP
            MSPDir: ./certs/ordererOrganizations/alcor.com/msp
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
            MSPDir: ./certs/peerOrganizations/org1.alcor.com/msp
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
                - Host: peer0.org1.alcor.com
                  Port: 7051
        - &Org2
            Name: Org2MSP
            ID: Org2MSP
            MSPDir: ./certs/peerOrganizations/org2.alcor.com/msp
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
                - Host: peer0.org2.alcor.com
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
            - orderer.alcor.com:7050
        BatchTimeout: 2s
        BatchSize:
            MaxMessageCount: 10
            AbsoluteMaxBytes: 99 MB
            PreferredMaxBytes: 512 KB
        Kafka:
            Brokers:
                - kafka.alcor.com:9092       # 可以填入多个kafka节点的地址
                - kafka.alcor.com:9093
                - kafka.alcor.com:9094
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

1. 生成创世纪区块
    
    ```bash
    cd /root/fabric/fabric-deploy
    ./bin/configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./genesisblock -channelID genesis
    ```
    生成创世纪区块文件 genesisblock ，并且指定创世区块的 channel id 是 genesis
    
1. 然后把区块文件 genesisblock 复制到 oderer.alcor.com机器上
    
    ```bash
    #登录到 cli 主机
    cd /root/fabric/fabric-deploy
    scp ./genesisblock  root@orderer.alcor.com:/opt/fabric/orderer
    ```
    
## 11. 启动 orderer 和 peer
1. 启动 orderer

    ```bash
    # 进入 orderer.alcor.com 主机的 /opt/fabric/orderer 目录,以后台进程方式启动orderer
    nohup ./startOrderer.sh &
    ```
    
    启动成功后，可以去任意一台 kafka 服务器上的控制台查看 topic 列表，是否有一个 genesis 的 channel。

    ```bash
    /opt/kafka_2.11-1.1.1/bin/kafka-topics.sh --zookeeper 192.168.188.111:2181 --list
    ```
  
2. 在4个 peer 上安装 couchDB
    
    详细介绍查看 ：
     [fabric peer 节点使用 CouchDB 来替换 LevelDB.](mweblib://15355039052312)
    
3. 启动4个 peer
    
    ```bash
    #分别进入4个 peer 主机的 /opt/fabric/peer 目录
    #以后台进程方式启动 peer
    nohup ./startPeer.sh &
    ```
    
4. `把 peer 主机上的 peer 进程注册成开机启动`
    
    * 在/etc/init.d 目录下建立一个  autoRunPeer.sh 文件。并且修改成可执行权限。
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
  
4. `把 orderer 主机上的 orderer 进程注册成开机启动`
    
    * 在/etc/init.d 目录下建立一个  autoRunOrderer.sh 文件。并且修改成可执行权限。
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

## 12. 用户账号创建
1. 在 cli 机器上建立存放用户账号信息的目录

    ```bash
    cd  /root/fabric/fabric-deploy
    mkdir users 
    cd users
    ```
    
2. 创立 org1的Admin 用户信息（对应到 peer0.org1.alcor.com 的节点）
    
    1. 创建保存 org1 的 Admin 用户信息的目录
    
        ```bash
        cd /root/fabric/fabric-deploy/users
        mkdir Admin@org1.alcor.com
        cd  Admin@org1.alcor.com
        ```
        
    2. 复制Admin@org1.alcor.com用户的证书
    
        ```bash
        cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org1.alcor.com/users/Admin@org1.alcor.com/* /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/
    
        ```
        
    3. 复制peer0.org1.alcor.com的配置文件(对应到 peer0.org1.alcor.com 的节点)
    
        ```bash
        cp /root/fabric/fabric-deploy/peer0.org1.alcor.com/core.yaml  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/
        ```
        
    4. 创建测试脚本(peer.sh)
        
        ```bash
        #!/bin/bash
        cd "/root/fabric/fabric-deploy/users/Admin@org1.alcor.com"
        PATH=`pwd`/../../bin:$PATH
        export FABRIC_CFG_PATH=`pwd`
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
        export CORE_PEER_TLS_KEY_FILE=./tls/client.key
        export CORE_PEER_MSPCONFIGPATH=./msp
        export CORE_PEER_ADDRESS=peer0.org1.alcor.com:7051
        export CORE_PEER_LOCALMSPID=Org1MSP
        export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
        export CORE_PEER_ID=peer0.org1.alcor.com
        export CORE_LOGGING_LEVEL=DEBUG
        peer $*
        ```
        注意：
            其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer0.org1.alcor.com 节点对应
        
    5. 运行 peer.sh 来查看节点 peer0.org1.aclor.com 的状态
    
        ```bash
        ./peer.sh node status
        ```
       ![-w1288](media/15382874126951/15383298724232.jpg)


3. 创立 org1的 User1 用户信息  （对应到 peer1.org1.alcor.com 的节点）
    
    1. 创建保存 org1 的 User1 用户信息的目录（对应到 peer1.org1.alcor.com）

        <font color="red"> 
        其实是 <font size=6>Admin </font>的用户证书，如果用的是User1的证书，在 peer node status 的时候，会出现错误：
        Error trying to connect to local peer: rpc error: code = Unknown desc = access denied
        
        </font>
    
        ```bash
        cd /root/fabric/fabric-deploy/users
        mkdir User1@org1.alcor.com
        cd  User1@org1.alcor.com
        ```
        
    2. 复制User1@org1.alcor.com用户的证书
    
        ```bash
        cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org1.alcor.com/users/Admin@org1.alcor.com/* /root/fabric/fabric-deploy/users/User1@org1.alcor.com/
    
        ```
        
    3. 复制peer1.org1.alcor.com的配置文件（对应到 peer1.org1.alcor.com）
    
        ```bash
        cp /root/fabric/fabric-deploy/peer1.org1.alcor.com/core.yaml  /root/fabric/fabric-deploy/users/User1@org1.alcor.com/
        ```
        
    4. 创建测试脚本(peer.sh)
        
        ```bash
        #!/bin/bash
        cd "/root/fabric/fabric-deploy/users/User1@org1.alcor.com"
        PATH=`pwd`/../../bin:$PATH
        export FABRIC_CFG_PATH=`pwd`
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
        export CORE_PEER_TLS_KEY_FILE=./tls/client.key
        export CORE_PEER_MSPCONFIGPATH=./msp
        export CORE_PEER_ADDRESS=peer1.org1.alcor.com:7051
        export CORE_PEER_LOCALMSPID=Org1MSP
        export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
        export CORE_PEER_ID=peer1.org1.alcor.com
        export CORE_LOGGING_LEVEL=DEBUG
        peer $*
        ```
        注意：
            其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer1.org1.alcor.com 节点对应
        
    5. 运行 peer.sh 来查看节点 peer1.org1.alcor.com 的状态
    
        ```bash
        ./peer.sh node status
        ```
    
4. 创立 org2的Admin 用户信息（对应到 peer0.org2.alcor.com 的节点）
    
    1. 创建保存 org2 的 Admin 用户信息的目录
    
        ```bash
        cd /root/fabric/fabric-deploy/users
        mkdir Admin@org2.alcor.com
        cd  Admin@org2.alcor.com
        ```
        
    2. 复制Admin@org2.alcor.com用户的证书
    
        ```bash
        cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org2.alcor.com/users/Admin@org2.alcor.com/* /root/fabric/fabric-deploy/users/Admin@org2.alcor.com/
    
        ```
        
    3. 复制peer0@org2.alcor.com的配置文件(对应到 peer0.org2.alcor.com 的节点)
    
        ```bash
        cp /root/fabric/fabric-deploy/peer0.org2.alcor.com/core.yaml  /root/fabric/fabric-deploy/users/Admin@org2.alcor.com/
        ```
        
    4. 创建测试脚本(peer.sh)
        
        ```bash
        #!/bin/bash
        cd "/root/fabric/fabric-deploy/users/Admin@org2.alcor.com"
        PATH=`pwd`/../../bin:$PATH
        export FABRIC_CFG_PATH=`pwd`
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
        export CORE_PEER_TLS_KEY_FILE=./tls/client.key
        export CORE_PEER_MSPCONFIGPATH=./msp
        export CORE_PEER_ADDRESS=peer0.org2.alcor.com:7051
        export CORE_PEER_LOCALMSPID=Org2MSP
        export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
        export CORE_PEER_ID=peer0.org2.alcor.com
        export CORE_LOGGING_LEVEL=DEBUG
        peer $*
        ```
        注意：
            其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer0.org1.alcor.com 节点对应
        
    5. 运行 peer.sh 来查看节点 peer0.org2.alcor.com 的状态
    
        ```bash
        ./peer.sh node status
        ```
        
5. 创立 org2的User1用户信息（对应到 peer1.org2.alcor.com 的节点）

      <font color="red"> 
        其实是 <font size=6>Admin </font>的用户证书，如果用的是User1的证书，在 peer node status 的时候，会出现错误：
        Error trying to connect to local peer: rpc error: code = Unknown desc = access denied
        </font>
  
    1. 创建保存 org2 的 User1 用户信息的目录
    
        ```bash
        cd /root/fabric/fabric-deploy/users
        mkdir User1@org2.alcor.com
        cd  User1@org2.alcor.com
        ```
        
    2. 复制Admin@org2.alcor.com用户的证书
    
        ```bash
        cp -rf  /root/fabric/fabric-deploy/certs/peerOrganizations/org2.alcor.com/users/Admin@org2.alcor.com/* /root/fabric/fabric-deploy/users/User1@org2.alcor.com/
    
        ```
        
    3. 复制peer0@org2.alcor.com的配置文件(对应到 peer0.org2.alcor.com 的节点)
    
        ```bash
        cp /root/fabric/fabric-deploy/peer1.org2.alcor.com/core.yaml  /root/fabric/fabric-deploy/users/User1@org2.alcor.com/
        ```
        
    4. 创建测试脚本(peer.sh)
        
        ```bash
        #!/bin/bash
        cd "/root/fabric/fabric-deploy/users/User1@org2.alcor.com"
        PATH=`pwd`/../../bin:$PATH
        export FABRIC_CFG_PATH=`pwd`
        export CORE_PEER_TLS_ENABLED=true
        export CORE_PEER_TLS_CERT_FILE=./tls/client.crt
        export CORE_PEER_TLS_KEY_FILE=./tls/client.key
        export CORE_PEER_MSPCONFIGPATH=./msp
        export CORE_PEER_ADDRESS=peer1.org2.alcor.com:7051
        export CORE_PEER_LOCALMSPID=Org2MSP
        export CORE_PEER_TLS_ROOTCERT_FILE=./tls/ca.crt
        export CORE_PEER_ID=peer1.org2.alcor.com
        export CORE_LOGGING_LEVEL=DEBUG
        peer $*
        ```
        注意：
            其中的 pwd 工作目录 和  CORE_PEER_ADDRESS  ， CORE_PEER_LOCALMSPID 要和 peer0.org1.alcor.com 节点对应
        
    5. 运行 peer.sh 来查看节点 peer0.org2.alcor.com 的状态
    
        ```bash
        ./peer.sh node status
        ```

        
## 13. channel 的准备和创建

<font color="red">
踩坑：channel ID 不能含有大写字母（myTestChannel , myChannel 这种命名是不行的，在创建 channel 的时候，会报错）
initializing configtx manager failed: bad channel ID: channel ID 'myTestChannel' contains illegal characters
</font>
    
1. 准备channel 文件。用configtxgen生成channel文件。 
    configtxgen 命令会去当前目录下的configtx.yaml（也可以通过FABRIC_CFG_PATH 指定） 中的profiles 部分下的和 -profile 参数对应的部分的内容，生成出一个 -outputCreateChannelTx  指定的输出文件

    ```bash
     cd /root/fabric/fabric-deploy/
    ./bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx mychannel.tx -channelID mychannel
    
    ```
    
## 14. 创建 channel

 1. 在Admin@org1.alcor.com目录中执行下面的命令，：
    
    ```bash
    cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh channel create -o orderer.alcor.com:7050 -c mychannel -f /root/fabric/fabric-deploy/mychannel.tx  -t 60s --tls true --cafile  /root/fabric/fabric-deploy/certs/ordererOrganizations/alcor.com/tlsca/tlsca.alcor.com-cert.pem

    ```
 
    执行完成后，会生成一个mychannel.block文件. 
    <font color=red>
    这个文件非常重要!所有加入到这个 channel 里面的 peer，都需要用到这个文件
    </font>
    
1. 将mychannel.block复制一份到User1@org1.alcor.com 和 Admin@org2.alcor.com、User1@org2.alcor.com中备用
    
    ```bash
    \cp -f /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/mychannel.block  /root/fabric/fabric-deploy/users/User1@org1.alcor.com/    
    \cp -f /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/mychannel.block  /root/fabric/fabric-deploy/users/Admin@org2.alcor.com/
    \cp -f /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/mychannel.block  /root/fabric/fabric-deploy/users/User1@org2.alcor.com/    
    ``` 

## 15.把 4个 peer加入到 channel 中

1. 把peer0.org1.alcor.com 加入到 channle 中

    ```bash
    cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh channel join -b mychannel.block
    #控制台返回成功后，可以用下面命令来查看
    ./peer.sh channel list
    ```

2. 把peer1.org1.alcor.com 加入到 channle 中
    
    ```bash
    cd  /root/fabric/fabric-deploy/users/User1@org1.alcor.com #这个其实还是org1.alcor.com 的 Admin 用户
    ./peer.sh channel join -b mychannel.block
    #控制台返回成功后，可以用下面命令来查看
    ./peer.sh channel list
    ```
    
3. 把peer0.org2.alcor.com 加入到 channle 中
    
    ```bash
    cd  /root/fabric/fabric-deploy/users/Admin@org2.alcor.com
    ./peer.sh channel join -b mychannel.block
    #控制台返回成功后，可以用下面命令来查看
    ./peer.sh channel list
    ```
    
4. 把peer1.org2.alcor.com 加入到 channle 中
    
    ```bash
    cd  /root/fabric/fabric-deploy/users/User1@org2.alcor.com #这个其实还是org2.alcor.com 的 Admin 用户
    ./peer.sh channel join -b mychannel.block
    #控制台返回成功后，可以用下面命令来查看
    ./peer.sh channel list
    ```


## 16.设置锚点 peer .

需要每个组织指定一个anchor peer，anchor peer是组织用来接收orderer下发的区块的peer。
锚点的设置 已经在 configtx.yaml 文件中配置，不需要在进行 peer channel update 操作了。

    
## 17. go 版本的 chaincode 的安装和部署（在 cli 主机上操作）

1. 安装 go 环境

    go 的下载官网 

    https://golang.org/dl/

    以 root 用户安装
    
    ```bash
    wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz

    tar -xvf  go1.10.3.linux-386.tar.gz

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
    
1. 拉取 demo 的 chaincode
    
    `这个需要先安装 gcc 组件`

    ```bash
    cd ~
    go get github.com/roamerxv/chaincode/fabric/examples/go/demo
    ```
    
    完成后，生成一个~/go 目录。下面有 src 和bin 目录。/root/go/src/github.com 目录下有个fabric 和 roamerxv 这2个目录。
    
        
1. chaincode 的安装

    ```bash
    cd /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

    ```
    由于 peer.sh 中指定了CORE_PEER_ADDRESS=peer0.org1.alcor.com:7051 ，所以，这个安装其实是把 chaincode 文件复制到 peer0.org1.alcor.com 这台机器的 /var/hyperledger/production/chaincodes/ 目录下. 文件名是 demo.0.0.1. 

    而 /var/hyperledger/production/chaincodes/ 这个路径是由 core.yaml 里面的 peer.fileSystemPath 这个属性指定的。
    
    ![-w399](media/15382874126951/15383353467012.jpg)

     
     ```bash
     #同时，可以在 cli 上，通过以下命令查看 peer 上的 chaincode 信息
     cd /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
     ./peer.sh chaincode list   --installed
     ```
     ![-w1124](media/15382874126951/15383354233467.jpg)


    <font color="red">
    注意: 这个安装需要在涉及到的所有 peer 上进行一遍,包括另外的组织 org2. 而且一定要用 admin用户来安装。
    所以，把签署后的 signed-demo-pack.out 复制到  ~/fabric/fabric-deploy/users/User1@org1.alcor.com , ~/fabric/fabric-deploy/users/Admin@org2.alcor.com 目录下.
    </font>
    
    ```bash
    
    #进入另外3个目录，再次安装 chaincode 到对应的 peer 上
    #这个是 安装到 peer1.org1.alcor.com
    cd  /root/fabric/fabric-deploy/users/User1@org1.alcor.com
    ./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

    
    #这个是 安装到 peer0.org2.alcor.com
    cd  /root/fabric/fabric-deploy/users/Admin@org2.alcor.com
    ./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo


    #这个是 安装到 peer1.org2.alcor.com
    cd  /root/fabric/fabric-deploy/users/User1@org2.alcor.com
    ./peer.sh chaincode install  -n demo -v 0.0.1 -p github.com/roamerxv/chaincode/fabric/examples/go/demo

    
    ```
    
1. chaincode 的初始化

    合约安装之后，需要且只需要进行一次初始化，只能由签署合约的用户进行初始化,并且所有的 peer 上的 docker 服务已经启动。谁签署了 chaincode，谁来进行实例化。

    ```bash
    cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh chaincode instantiate -o orderer.alcor.com:7050 --tls true --cafile  /root/fabric/fabric-deploy/certs/ordererOrganizations/alcor.com/tlsca/tlsca.alcor.com-cert.pem -C mychannel -n demo -v 0.0.1 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')"
    ```
    第一次进行合约初始化的时候的会比较慢，因为peer 上需要创建、启动容器。
    
1. chaincode的调用

    ```bsh
    cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh chaincode invoke -o orderer.alcor.com:7050  --tls true --cafile /root/fabric/fabric-deploy/certs/ordererOrganizations/alcor.com/tlsca/tlsca.alcor.com-cert.pem  -C mychannel -n demo  -c '{"Args":["write","key1","key1value中文isabc"]}'
    ```
    <font color="red">
    chaincode 的调用，可以调用任意一台安装了这个 chaincode 的peer。这个时候被调用的 peer 上会启动相应的 chaincode 的 docker。
    </font>
    
    进行查询操作时，不需要指定orderer，例如：
    
    ```bash
    cd /root/fabric/fabric-deploy/users/User1@org1.alcor.com
    ./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'
    ```
    
1. chaincode 的更新
    
    新合约的打包和签署
    ```bash
    cd /home/fabric/fabric-deploy/users/Admin@org1.alcor.com
    
    ./peer.sh chaincode package demo-pack-2.out -n demo -v 0.0.2 -s -S -p github.com/roamerxv/chaincode/fabric/examples/go/demo
    
    ./peer.sh chaincode signpackage demo-pack-2.out signed-demo-pack-2.out    
     ```
    
    新的合约也需要在每个peer上单独安装。
    
    ```bash
    #安装到peer0.org1.alcor.com
    cd /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh chaincode install ./signed-demo-pack-2.out
    
    #安装到peer1.org1.alcor.com
    cd /root/fabric/fabric-deploy/users/User1@org1.alcor.com
    ./peer.sh chaincode install ../Admin@org1.alcor.com/signed-demo-pack-2.out
    
    #安装到peer0.org2.alcor.com
    cd /root/fabric/fabric-deploy/users/Admin@org2.alcor.com
    ./peer.sh chaincode install ../Admin@org1.alcor.com/signed-demo-pack-2.out
    
     #安装到peer1.org2.alcor.com
    cd /root/fabric/fabric-deploy/users/User1@org2.alcor.com
    ./peer.sh chaincode install ../Admin@org1.alcor.com/signed-demo-pack-2.out
    ```
    
    更新的合约不需要初始化，需要进行更新操作。
    
    ```bash
    cd /home/fabric/fabric-deploy/users/Admin@org1.alcor.com
    ./peer.sh chaincode upgrade -o orderer.alcor.com:7050 --tls true --cafile  /root/fabric/fabric-deploy/certs/ordererOrganizations/alcor.com/tlsca/tlsca.alcor.com-cert.pem  -C mychannel -n demo -v 0.0.2 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')"
    ```
    
1. 查询key的历史记录
```bash
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["history","key1"]}'
```

## 18. java 版本的 chaincode 的安装和部署（在 cli 主机上操作）

* 拉取 java chaincode 的代码
    在 各个 `peer` 的主机上进行
    ```bash
    cd /root
    git clone  https://github.com/hyperledger/fabric-chaincode-java
    #安装 java 和 gradle(略过)
    
    # gradle 编译 chaincode 的支持包(Build java shim jars (proto and shim jars) and install them to local maven repository.),好像需要 翻墙（gradle 指定 proxy的方法是在 gradle 命令后面跟-D参数：  -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016）
    cd /root/fabric-chaincode-java/
    gradle clean build install  -x test -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016
    
    # 在 peer 上生成在 peer 本地机上需要的 docker javaenv image
    gradle buildImage  -x test -Dhttp.proxyHost=192.168.2.11 -Dhttp.proxyPort=8016

    
    # 编译chaincode 的项目
    cd /root/fabric-chaincode-java/fabric-chaincode-example-gradle
    gradle clean build shadowJar

    
    #生成的 jar 文件位于    ./build/libs  目录下的 chaincode.jar
    ```

    ```bash
    cd /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
    # chaincode 打包
    ./peer.sh chaincode package  mycc-pack.out -l java -n mycc -v 1.0.0 -s -S -p /root/fabric-chaincode-java/fabric-chaincode-example-gradle/src/main/java/org/hyperledger/fabric/example
    
    # chaincode 签署
    ./peer.sh chaincode signpackage mycc-pack.out signed-mycc-pack.out
    
    # chaincode 安装
    ./peer.sh chaincode install ./signed-mycc-pack.out
    
     ./peer.sh chaincode install -l java  -n mycc -v 1.0.0 -p /root/fabric-chaincode-java/fabric-chaincode-example-gradle
    
    #实例化 chaincode

    ./peer.sh chaincode instantiate -o orderer.alcor.com:7050 --tls true --cafile ./tlsca.alcor.com-cert.pem -C mychannel -n mycc -v 1.0.0 -c  '{"Args":["init","roamer","100","dly","200"]}' -P "OR('Org1MSP.member','Org2MSP.member')"
    
    ```

`踩坑`：
1. 下载 image  ： hyperledger/fabric-javaenv:amd64-1.3.0 不存在。
    解决办法: 修改 peer 上的 core.yaml 文件中的chaincode-java-runtime 部分，直接指定
    
    ```yaml
    java:
        #runtime: $(DOCKER_NS)/fabric-javaenv:$(ARCH)-$(PROJECT_VERSION)
        runtime: $(DOCKER_NS)/fabric-javaenv:$(ARCH)-1.3.0-rc1
    ```
    
    kill 掉原来的 peer 进程，再启动 peer 。在 cli 上重新 instance CC 。peer 节点上会自动 pull image。如果不重启 peer，core.yaml 不会起作用,一直报同样的错误。
    

## 19. fabric explorer 的安装和使用

[hyperledger explorer(0.3.7) 安装](mweblib://15366371522047)

## 20. Fabric CA的安装和使用

1. 在 ca.alcor.com 主机上安装 Fabric-ca 1.3 
    1. 安装 go 环境
    
        ```bash
        cd /root
        wget https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
        tar -xvf  go1.10.3.linux-386.tar.gz
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
    
    2. fabirc-ca的下载和编译
        
        * 通过源码编译的方式
        
            ```bash
            yum install libtool   libtool-ltdl-devel
    
            cd /root
            go get -u github.com/hyperledger/fabric-ca/cmd/...
            cd $GOPATH/bin
            # 发现有一下2个执行文件
            fabric-ca-client  fabric-ca-server
            
            #也可以到 $GOPATH/src/github.com/hyperledger/fabric-ca 目录下，用 make fabric-ca-server 和 fabric-ca-client 命令进行编译
            ```
            
        *  直接下载的方式
            ```bash
            cd \root
            wget https://nexus.hyperledger.org/service/local/repositories/releases/content/org/hyperledger/fabric-ca/hyperledger-fabric-ca-1.3.0-stable/linux-amd64.1.3.0-stable-fe659db/hyperledger-fabric-ca-1.3.0-stable-linux-amd64.1.3.0-stable-fe659db.tar.gz
            ```
        
   1. 未完！待续...
