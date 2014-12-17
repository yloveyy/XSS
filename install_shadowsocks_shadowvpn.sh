#!/bin/bash
#Program:
#	Install shadowsocks and shadowvpn
#History
#2014/12/12
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
######################  Defaults  #######################

#Update system
apt-get update
apt-get install git

#Detecting whether the directory already exists
test -d /root/shadowsocks || mkdir /root/shadowsocks
test -d /root/shadowvpn || mkdir /root/shadowvpn

#Install shadowsocks
cd /root/shadowsocks
git clone https://github.com/madeye/shadowsocks-libev.git
cd shadowsocks-libev
apt-get install build-essential autoconf libtool libssl-dev
./configure --prefix=/usr
make && make install
mkdir /etc/shadowsocks-libev
cp ./debian/shadowsocks-libev.init /etc/init.d/shadowsocks-libev
cp ./debian/shadowsocks-libev.default /etc/default/shadowsocks-libev
cp ./debian/config.json /etc/shadowsocks-libev/config.json
chmod +x /etc/init.d/shadowsocks-libev

#Install shadowvpn
cd /root/shadowvpn
apt-get install build-essential automake libtool
git clone https://github.com/clowwindy/ShadowVPN.git
cd ShadowVPN
git init
git submodule update --init
./autogen.sh
./configure --enable-static --sysconfdir=/etc
make && sudo make install

#Production start-up script
cat>/root/shadowsocks_and_shadowvpn_startup.sh<<EOF
#!/bin/bash
#Program:
#	This program let shadowsocks and shadowvpn start at the systerm boot
#History
#2014/12/12
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
######################  Defaults  #######################
/etc/init.d/shadowsocks-libev start
sudo shadowvpn -c /etc/shadowvpn/server.conf -s start
exit 0
EOF

#Configure iptables
apt-get install iptables

iptables -F && iptables -X && iptables -Z

cat>/etc/iptables.abc.rules<<EOF
*filter
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
-A INPUT -j DROP
COMMIT
EOF

sudo iptables-restore < /etc/iptables.abc.rules
sudo iptables-save > /etc/iptables.up.rules

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

#END
exit 0

