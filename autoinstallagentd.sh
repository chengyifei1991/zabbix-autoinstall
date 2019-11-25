#!/bin/bash
# 定义函数
check_results=`rpm -qa zabbix-agent |cut -d- -f2`
check_results2=`rpm -qa zabbix-release`
check_fwstat=`systemctl status firewalld`
check_sestat=`getenforce`
SYSTEM=`rpm -q centos-release|cut -d- -f3`
#repostat=`cat /etc/yum.repos.d/CentOS-Base.repo |grep 'name=CentOS-$releasever - Base - mirrors.aliyun.com'|cut -d- -f4|cut -d. -f2`
check_net=`ping -c 1 'repo.zabbix.com'> /dev/null 2>&1`
myFile=/root/zabbix-agent-3.4.15-1.el7.x86_64.rpm
# 判断系统版本是否为Centos7
if [ $SYSTEM != "7" ]; 
then
	echo "Cannot be automatically installed on Centos systems below version 7.0 "
	exit 1;
fi

#if [ $repostat = "aliyun" ];
#then
#	echo "Aliyun repo had replaced"	
#else 
#	echo  "Now  this shell will change yum repoconfig"
#	curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null
#	curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo >/dev/null	
#fi
# 修改防火墙和selinux的配置
echo "add firewall list and disabled selinux"
firewall-cmd --permanent --zone=public --add-port=10050/tcp
firewall-cmd --permanent --zone=public --add-port=10051/tcp
firewall-cmd --reload
setenforce 0
rpm -ih $myFile
# 开始更改配置
if [ $? -eq 0 ] 
then  
	cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf_bk
	echo "">/etc/zabbix/zabbix_agentd.conf 
	read  -p "please input zabbix_serverIP:"  zabbix_serverIP
	sed -i.ori  '1a Server='$zabbix_serverIP'' /etc/zabbix/zabbix_agentd.conf
	sed -i.ori '2a ServerActive='$zabbix_serverIP'' /etc/zabbix/zabbix_agentd.conf
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
	echo "The configuration has been successfully replaced"
	cp /root/userparameter_diskio.conf /etc/zabbix/zabbix_agentd.d/
	cp /root/userparameter_mvsp_thread.conf /etc/zabbix/zabbix_agentd.d/
	echo "zabbix-agent was installed successfully!"
else
	echo "install failed,please check"
	exit 1;
fi  
# 启动服务
systemctl start  zabbix-agent.service 
if [ $? -eq 0 ] 
then
	echo "set zabbix_agentd start with system"
	systemctl enable zabbix-agent.service	
else
	echo "start error,please check"
	exit 1;
fi
