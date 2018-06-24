#!/bin/bash
#Program:
#	Install shadowsocks and others
#History
#2014/12/12
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
######################  Defaults  #######################

apt-get update
apt-get install vim git screen

# configure vim
cat>/root/.vimrc<<EOF
set number
syntax on
EOF
    
# install shadowsocksR
git clone https://github.com/chnt7305/shadowsocksr.git
cd shadowsocksr
bash initcfg.sh
vim user-config

cat>/etc/init.d/shadowsocksr<<EOF
#!/bin/sh
# chkconfig: 2345 90 10
# description: Start or stop the Shadowsocks R server
#
### BEGIN INIT INFO
# Provides: Shadowsocks-R
# Required-Start: $network $syslog
# Required-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Start or stop the Shadowsocks R server
### END INIT INFO

# Author: Yvonne Lu(Min) <min@utbhost.com>

name=shadowsocksr
PY=/usr/bin/python
SS=/root/shadowsocksr/shadowsocks/server.py
SSPY=server.py
conf=/root/shadowsocksr/user-config.json

start(){
    $PY $SS -c $conf -d start
    RETVAL=$?
    if [ "$RETVAL" = "0" ]; then
        echo "$name start success"
    else
        echo "$name start failed"
    fi
}

stop(){
    pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${SSPY}" | awk '{print $2}'`
    if [ ! -z $pid ]; then
        $PY $SS -c $conf -d stop
        RETVAL=$?
        if [ "$RETVAL" = "0" ]; then
            echo "$name stop success"
        else
            echo "$name stop failed"
        fi
    else
        echo "$name is not running"
        RETVAL=1
    fi
}

status(){
    pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${SSPY}" | awk '{print $2}'`
    if [ -z $pid ]; then
        echo "$name is not running"
        RETVAL=1
    else
        echo "$name is running with PID $pid"
        RETVAL=0
    fi
}

case "$1" in
'start')
    start
    ;;
'stop')
    stop
    ;;
'status')
    status
    ;;
'restart')
    stop
    start
    RETVAL=$?
    ;;
*)
    echo "Usage: $0 { start | stop | restart | status }"
    RETVAL=1
    ;;
esac
exit $RETVAL
EOF

chmod 755 /etc/init.d/shadowsocksr 

# Configure iptables
apt-get install iptables
#iptables -F && iptables -X && iptables -Z
cat>/etc/iptables.test.rules<<EOF
*filter
# Allows all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT

# Accepts all established inbound connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allows all outbound traffic
# You could modify this to only allow certain traffic
-A OUTPUT -d xxx.xxx.xxx.xxx -p tcp --sport xxxx -j ACCEPT
-A OUTPUT -p tcp --sport xxxx -j DROP

# Allows SSH connections from anywhere
-A INPUT -p tcp --dport 22 -j ACCEPT
# Open TCP port
-A INPUT -p tcp --dport xxxx -j ACCEPT

# Allow ping
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

# log iptables denied calls (access via 'dmesg' command)
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# Reject all other inbound - default deny unless explicitly allowed policy
-A INPUT -j DROP
-A OUTPUT -j ACCEPT
COMMIT
EOF

iptables-restore < /etc/iptables.test.rules
iptables-save > /etc/iptables.up.rules

cat>/etc/network/if-post-down.d/iptables<<EOF
#!/bin/bash
iptables-save > /etc/iptables.rules
EOF
chmod +x /etc/network/if-post-down.d/iptables

cat>/etc/network/if-pre-up.d/iptables<<EOF
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOF
chmod +x /etc/network/if-pre-up.d/iptables

# change the time zone
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#END
exit 0
