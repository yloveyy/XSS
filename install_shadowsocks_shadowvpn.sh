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
#test -d /root/shadowvpn || mkdir /root/shadowvpn

#Install shadowsocks
cd /root/shadowsocks
git clone https://github.com/shadowsocks/shadowsocks-libev.git
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
#cd /root/shadowvpn
#apt-get install build-essential automake libtool
#git clone https://github.com/clowwindy/ShadowVPN.git
#cd ShadowVPN
#git init
#git submodule update --init
#./autogen.sh
#./configure --enable-static --sysconfdir=/etc
#make && make install

#Configure iptables
apt-get install iptables

iptables -F && iptables -X && iptables -Z

cat>/etc/iptables.rules<<EOF
*filter
# Allows all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT

# Accepts all established inbound connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allows all outbound traffic
# You could modify this to only allow certain traffic
-A OUTPUT -j ACCEPT

# Allows TCP and UDP connections from anywhere
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allowable error time 1 minute
-A INPUT -p tcp -m state --syn --state NEW --dport 22 -m limit --limit 1/minute --limit-burst 1 -j ACCEPT
-A INPUT -p tcp -m state --syn --state NEW --dport 22 -j DROP

# Allow ping
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

# log iptables denied calls (access via 'dmesg' command)
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# Reject all other inbound - default deny unless explicitly allowed policy
-A INPUT -j DROP

COMMIT
EOF

iptables-restore < /etc/iptables.rules
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

#END
exit 0
