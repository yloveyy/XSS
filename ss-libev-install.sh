#!/bin/bash
#
#Program:
#Install shadowsocks-libev 3.x on Ubuntu 14.04 and higher version
#Run the script as root
#History
#2018/06/24
#Author
#https://github.com/chnt7305
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
######################  Defaults  #######################

apt-get update
apt-get install git screen haveged -y

git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive

apt-get install --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev automake -y

# Build libsodium
export LIBSODIUM_VER=1.0.16
wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
tar xvf libsodium-$LIBSODIUM_VER.tar.gz
pushd libsodium-$LIBSODIUM_VER
./configure --prefix=/usr && make
make install
popd
ldconfig

#Build mbedtls
export MBEDTLS_VER=2.11.0
wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz
pushd mbedtls-$MBEDTLS_VER
make SHARED=1 CFLAGS=-fPIC
make DESTDIR=/usr install
popd
ldconfig

#Build shadowsocks-libev
./autogen.sh && ./configure && make
make install

mv /usr/local/bin/ss-* /usr/bin/
mkdir -p /etc/shadowsocks-libev
cp ./debian/shadowsocks-libev.init /etc/init.d/shadowsocks-libev		
cp ./debian/shadowsocks-libev.default /etc/default/shadowsocks-libev		
cp ./debian/shadowsocks-libev.service /lib/systemd/system/		
cp ./debian/config.json /etc/shadowsocks-libev/config.json
chmod +x /etc/init.d/shadowsocks-libev

# make sure haveged configured to start on boot
update-rc.d haveged defaults

echo "Shadowsocks-libev install completed"

exit 0
