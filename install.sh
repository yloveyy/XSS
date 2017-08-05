#!/bin/bash
#Program:
#	Install shadowsocks and others
#History
#2014/12/12
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
######################  Defaults  #######################

# install shadowsocks-libev 2.6.0-1 (the source code has been backed up)
# for debian7.X user please according the follow comments to 
# enable debian-backports to install systemd-compatibility packages like dh-systemd or init-system-helpers
# vi /etc/apt/sources.list
# deb http://ftp.debian.org/debian wheezy-backports main
# apt-get update
# apt-get install git
# apt-get install --no-install-recommends build-essential autoconf libtool libssl-dev \
#    gawk debhelper dh-systemd init-system-helpers pkg-config asciidoc xmlto apg libpcre3-dev
# git clone https://github.com/shadowsocks/shadowsocks-libev.git
# cd shadowsocks-libev
# dpkg-buildpackage -b -us -uc -i
# cd ..
# dpkg -i shadowsocks-libev*.deb

# install shadowsocks-libev 3.x frome soure
apt-get update
apt-get install vim git

# configure vim
cat>/root/.vimrc<<EOF
set number
syntax on
EOF

# install shadowsocks-libev 3.x
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
sh -c 'printf "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list'
apt-get update
apt-get -t jessie-backports install libmbedtls-dev libsodium-dev
apt-get install --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake
./autogen.sh
./configure --prefix=/usr
make && make install
mkdir -p /etc/shadowsocks-libev
cp ./debian/shadowsocks-libev.init /etc/init.d/shadowsocks-libev		
cp ./debian/shadowsocks-libev.default /etc/default/shadowsocks-libev		
cp ./debian/shadowsocks-libev.service /lib/systemd/system/		
cp ./debian/config.json /etc/shadowsocks-libev/config.json
chmod +x /etc/init.d/shadowsocks-libev
    
# install shadowsocksR
git clone https://github.com/chnt7305/shadowsocksr.git
cd shadowsocksr
bash initcfg.sh
cd ..

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

chmod 755 /etc/init.d/shadowsocksr ; update-rc.d shadowsocksr defaults ; service shadowsocksr start

# install net-speeder
# apt-get install unzip
# apt-get install libnet1-dev
# apt-get install libpcap0.8-dev
# wget https://github.com/chnt7305/net-speeder/archive/master.zip
# unzip master.zip
# venetX,OpenVZ not Xen,KVM
# sh build.sh -DCOOKED

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
-A OUTPUT -j ACCEPT

# Allows SSH connections from anywhere
-A INPUT -p tcp --dport 22 -j ACCEPT
# Open serial port
-A INPUT -p tcp --dport 10010:10086 -j ACCEPT

# Allow ping
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

# log iptables denied calls (access via 'dmesg' command)
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# Reject all other inbound - default deny unless explicitly allowed policy
-A INPUT -j DROP

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
