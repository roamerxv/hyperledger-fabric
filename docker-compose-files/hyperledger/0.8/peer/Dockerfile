FROM hyperledger/fabric-peer
MAINTAINER "roamer <roamerxv@gmail.com>"

#安装 vim
RUN apt-get update && apt-get -y install vim

#update system timezone
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#update application timezone
RUN echo "Asia/Shanghai" >> /etc/timezone