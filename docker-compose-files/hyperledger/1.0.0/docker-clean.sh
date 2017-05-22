echo "删除所有容器"
docker rm -f $(docker ps -aq)

echo "删除相关镜像"
docker rmi -f $(docker images 08_* -aq)
docker rmi -f $(docker images dev-* -aq)

echo "启用 roamerxv 的 fabric-javaenv 镜像"
docker tag  roamerxv/fabric-javaenv hyperledger/fabric-javaenv:x86_64-1.0.0-preview
