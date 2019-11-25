#!/bin/bash
#suto install zabbix_proxy
# 定义函数
check_results=`rpm -qa zabbix-proxy |cut -d- -f2`
check_results2=`rpm -qa zabbix-release`
check_sestat=`getenforce`
SYSTEM=`rpm -q centos-release|cut -d- -f3`
repostat=`cat /etc/yum.repos.d/CentOS-Base.repo |grep 'name=CentOS-$releasever - Base - mirrors.aliyun.com'|cut -d- -f4|cut -d. -f2`
myFile=/root/zabbix-agent-3.4.15-1.el7.x86_64.rpm
myFile2=/root/zabbix-proxy-mysql-3.4.15-1.el7.x86_64.rpm
# 判断系统版本是否为Centos7
if [ $SYSTEM != "7" ]; 
then
	echo "Cannot be automatically installed on Centos systems below version 7.0 "
	exit 1;
fi
if [ $repostat = "aliyun" ];
then
	echo "Aliyun repo had replaced"	
else 
	echo  "Now  this shell will change yum repoconfig"
	curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null
	curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo >/dev/null	
fi
# 修改防火墙和selinux的配置
echo "add firewall list and disabled selinux"
firewall-cmd --permanent --zone=public --add-port=10050/tcp
firewall-cmd --permanent --zone=public --add-port=10051/tcp
firewall-cmd --reload
setenforce 0
# sed -i 's/SELINUX=enforcing/SELINUX='disabled'/' /etc/sysconfig/selinux
# sed -i.ori '7a SELINUX='disabled'/' /etc/sysconfig/selinux
#如果没有mysql就安装mysql
if [ -f /mvsp/mysql/bin/mysql ]; 
then
	/mvsp/mysql/bin/mysql -uroot -p123456789 -e 'create database zabbix_proxy character set utf8 collate utf8_bin;'
	/mvsp/mysql/bin/mysql -uroot -p123456789 -e 'grant all privileges on zabbix_proxy.* to zabbix@localhost identified by "zabbix";'
	echo "uninstall old zabbix-release && install local zabbix-agent"
	rpm -ih $myFile
	yum -y install $myFile2
	zcat /usr/share/doc/zabbix-proxy-mysql-3.4.15/schema.sql.gz | /mvsp/mysql/bin/mysql -uzabbix -pzabbix zabbix_proxy
else
	yum install fping mariadb
	systemctl start mariadb 
	echo "uninstall old zabbix-release && install local zabbix-agent"
	rpm -ih $myFile
	yum install $myFile2
	mysql -uroot -p -e 'create database zabbix_proxy character set utf8 collate utf8_bin;'
	mysql -uroot -p -e 'grant all privileges on zabbix_proxy.* to zabbix@localhost identified by "zabbix";'
	zcat /usr/share/doc/zabbix-proxy-mysql-3.4.15/schema.sql.gz | mysql -uzabbix -pzabbix
fi

# 开始更改配置
if [ $? -eq 0 ] 
then      
	sed -i 's/Server=127.0.0.1/Server='124.161.255.226'/' /etc/zabbix/zabbix_proxy.conf
	sed -i 's/ServerActive=127.0.0.1/ServerActive='124.161.255.226'/' /etc/zabbix/zabbix_proxy.conf
	read  -p "please input proxy HOSTNAME:"  HOSTNAME
	sed -i.ori 's/Hostname=Zabbix\ Server/Hostname='$HOSTNAME'/' /etc/zabbix/zabbix_proxy.conf
	sed -i.ori '191a DBPassword=zabbix' /etc/zabbix/zabbix_proxy.conf
	sed -i.ori '198a DBSocket=/mvsp/mysql/var/mysql.sock' /etc/zabbix/zabbix_proxy.conf
	sed -i.ori '217a ProxyLocalBuffer=5' /etc/zabbix/zabbix_proxy.conf 
	sed -i.ori '226a ProxyOfflineBuffer=5' /etc/zabbix/zabbix_proxy.conf
	cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf_bk
	echo "">/etc/zabbix/zabbix_agentd.conf 
	sed -i.ori  '1a Server='127.0.0.1'' /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '2a ServerActive='127.0.0.1'' /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '3a HostMetadataItem=system.uname' /etc/zabbix/zabbix_agentd.conf
	read  -p "请输入主机名称，最好以IP命名:"  HOSTNAME
	sed -i.ori '4a Hostname='$HOSTNAME'' /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '5a AllowRoot='1'' /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '6a UnsafeUserParameters='1''  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '7a MaxLinesPerSecond='180''  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '8a EnableRemoteCommands='1''  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '9a LogFileSize='1''  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '10a LogFile=/var/log/zabbix/zabbix_agentd.log'  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '11a PidFile=/var/run/zabbix/zabbix_agentd.pid'  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '12a Include=/etc/zabbix/zabbix_agentd.d/*.conf'  /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '13a Timeout='30''  /etc/zabbix/zabbix_agentd.conf
	cp /root/userparameter_diskio.conf /etc/zabbix/zabbix_agentd.d/
	cp /root/userparameter_mvsp_thread.conf /etc/zabbix/zabbix_agentd.d/ 
	echo "The configuration has been successfully replaced"
	echo "zabbix-agent and proxy  was installed successfully!"
else
	echo "install failed,please check"
	exit 1;
fi 

#启动服务
systemctl start  zabbix-agent.service && systemctl start  zabbix-proxy.service 
if [ $? -eq 0 ] 
then
	echo "set zabbix_agentd and proxy start with system"
	systemctl enable zabbix-agent.service
	systemctl enable zabbix-proxy.service||echo "start error,please check"	
fi
