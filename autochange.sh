#!/bin/bash
read -p "是否已经解压相关自定义脚本到指定位置？输入Y 是 输入N 不是"danan
case in $danan 
	Y)
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
        ;;
	N)
       echo "请解压文件到指定位置" 
        ;;
    *)
        echo "请输入: Y或者N"
        ;;
esac

