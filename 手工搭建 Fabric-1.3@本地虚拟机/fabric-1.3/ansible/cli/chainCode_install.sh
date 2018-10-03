#! /bin/bash
echo "生成 CC "
cd /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
./peer.sh chaincode package demo-pack.out -n demo -v 0.0.1 -s -S -p github.com/roamerxv/chaincode/fabric/examples/go/demo
echo "对 CC 签名并且打包"
./peer.sh chaincode signpackage demo-pack.out signed-demo-pack.out

echo "查看 peer0.org1.alcor.com 上的 CC 列表"
 ./peer.sh chaincode list   --installed

echo "复制 CC 到 其余的 peer 节点"
cp /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/signed-demo-pack.out   /root/fabric/fabric-deploy/users/User1@org1.alcor.com
cp /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/signed-demo-pack.out   /root/fabric/fabric-deploy/users/Admin@org2.alcor.com 
cp /root/fabric/fabric-deploy/users/Admin@org1.alcor.com/signed-demo-pack.out   /root/fabric/fabric-deploy/users/User1@org2.alcor.com
#进入另外3个目录，再次安装 chaincode 到对应的 peer 上
#这个是 安装到 peer1.org1.alcor.com
echo "安装 CC 到 所有节点"
cd /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
./peer.sh chaincode install ./signed-demo-pack.out

cd  /root/fabric/fabric-deploy/users/User1@org1.alcor.com
./peer.sh chaincode install ./signed-demo-pack.out
#这个是 安装到 peer0.org2.alcor.com
cd  /root/fabric/fabric-deploy/users/Admin@org2.alcor.com
./peer.sh chaincode install ./signed-demo-pack.out
#这个是 安装到 peer1.org2.alcor.com
cd  /root/fabric/fabric-deploy/users/User1@org2.alcor.com
./peer.sh chaincode install ./signed-demo-pack.out

echo "实例化 CC"
cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
./peer.sh chaincode instantiate -o orderer.alcor.com:7050 --tls true --cafile ./tlsca.alcor.com-cert.pem -C mychannel -n demo -v 0.0.1 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')"

echo "调用 cc 代码 的 write 功能 "
cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
./peer.sh chaincode invoke -o orderer.alcor.com:7050  --tls true --cafile ./tlsca.alcor.com-cert.pem -C mychannel -n demo  -c '{"Args":["write","key1","key1value中文isabc"]}'

echo "在 peer0.org1.alcor.com 上调用 CC 的查看功能"
cd  /root/fabric/fabric-deploy/users/Admin@org1.alcor.com
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'

echo "在 peer1.org1.alcor.com 上调用 CC 的查看功能"
cd  /root/fabric/fabric-deploy/users/User1@org1.alcor.com
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'

echo "在 peer0.org2.alcor.com 上调用 CC 的查看功能"
cd  /root/fabric/fabric-deploy/users/Admin@org2.alcor.com
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'

echo "在 peer1.org2.alcor.com 上调用 CC 的查看功能"
cd  /root/fabric/fabric-deploy/users/User1@org2.alcor.com
./peer.sh chaincode query -C mychannel -n demo -c '{"Args":["query","key1"]}'
