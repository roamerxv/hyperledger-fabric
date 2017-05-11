cat <<EOF
+------------------------------------------------------------------------+
|             ========= Wellcom to install yum ============              |
+------------------------------------------------------------------------+
EOF
yum -y update
yum -y install  epel-release
yum -y install  zip unzip bzip2 tree 
yum -y install  net-tools 
yum -y install  yum-plugin-security yum-utils createrepo
yum -y install  git wget curl 
yum -y install  vim
yum -y install  python-pip

echo  -e "Init yum installed\n"



cat <<EOF
+------------------------------------------------------------------------+
|        ==========   安装时间同步			          ============       |
+------------------------------------------------------------------------+
EOF
yum install -y ntpdate
ntpdate us.pool.ntp.org

yum -y install ntp
systemctl enable ntpd
systemctl start ntpd



cat <<EOF
+------------------------------------------------------------------------+
|        ==========   安装docker 官方维护版本         ============       |
+------------------------------------------------------------------------+
EOF

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum -y update
yum -y install  docker-engine
systemctl enable docker
systemctl restart  docker

echo -e "docker 安装完成\n"



cat <<EOF
+------------------------------------------------------------------------+
|             ==========Wellcom to Centos system init ============       |
+------------------------------------------------------------------------+
EOF

#ntp set
yum -y install ntp
echo "* 3 * * * /usr/sbin/ntpdate 202.118.1.81 > /dev/null>&1" >> /etc/crontab
service crond restart
echo -e "\n"


cat <<EOF
+------------------------------------------------------------------------+
|             ========= 更新pip			       ============              |
+------------------------------------------------------------------------+
EOF
pip install --upgrade pip
echo  -e "pip 更新完成\n"

cat <<EOF
+------------------------------------------------------------------------+
|             ========= 安装docker-compse       ============              |
+------------------------------------------------------------------------+
EOF
pip install -U docker-compose
docker-compose -v
echo  -e " docker-compose 安装完成\n"

cat <<EOF
+------------------------------------------------------------------------+
|             ========= 关闭访问墙		       ============              |
+------------------------------------------------------------------------+
EOF
systemctl stop firewalld.service
systemctl disable firewalld.service

cat <<EOF
+------------------------------------------------------------------------+
|             ========= 关闭 Selinux 			   ============          |
+------------------------------------------------------------------------+
EOF

#disable selinux
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
echo  -e "selinux is disabled,but you must reboot!\n"

#disable ipv6
cat <<EOF
+------------------------------------------------------------------------+
|             ========= Wellcom to disable IPv6 ============             |
+------------------------------------------------------------------------+
EOF
echo "alias net-pf-10 off" >> /etc/modprobe.conf
echo "alias ipv6 off" >> /etc/modprobe.conf
/sbin/chkconfig --level 35 ip6tables off
echo  -e "ipv6 is disabled!\n"



cat <<EOF
+------------------------------------------------------------------------+
|                                     修改时区&&设置时间                   |
+------------------------------------------------------------------------+
EOF
timedatectl set-ntp yes
timedatectl set-timezone Asia/Shanghai


cat <<EOF
+------------------------------------------------------------------------+
|             =======    修改系统字符集zh_CN.UTF-8		  ============   |
+------------------------------------------------------------------------+
EOF

echo $LANG >>/server/logs/sys-install.log
sed -i 's/en/zh_CN.UTF-8/g' /etc/locale.conf
source /etc/locale.conf
echo $LANG >>/server/logs/sys-install.log
 
#临时修改系统字符集
#LANG=zh_CN.UTF-8


cat <<EOF
+------------------------------------------------------------------------+
|=== 内核优化sysctl.conf && 调整文件描述符ulimit（即单个进程的最大文件打开数  ==|
+------------------------------------------------------------------------+
EOF

cp /etc/sysctl.conf /etc/sysctl.conf.bak`date +%F` 
echo "net.ipv4.ip_local_port_range = 1024 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_window_scaling = 0
net.ipv4.tcp_sack = 0
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_no_metrics_save = 1
net.core.somaxconn = 65535
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2" >/etc/sysctl.conf 
sysctl -p >>/server/logs/sys-install.log
sysctl -w net.ipv4.route.flush=1
echo "ulimit -HSn 65536" >> /etc/rc.local
echo "ulimit -HSn 65536" >> /root/.bash_profile
ulimit -HSn 65535
ulimit -n >>/server/logs/sys-install.log


cat <<EOF
+------------------------------------------------------------------------+
|             ========= 启动相关服务			   ============              |
+------------------------------------------------------------------------+
EOF
pip install --upgrade pip
systemctl enable  docker
systemctl restart docker

cat <<EOF
+------------------------------------------------------------------------+
|             ========= docker 加速			   ============              |
+------------------------------------------------------------------------+
EOF
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://d19de388.m.daocloud.io
sysctl -w net.ipv4.ip_forward=1
systemctl restart docker


