#!/bin/sh
file_name="/tmp/log/wget.log"   # Log path
kaishi=`date +%Y-%m-%d-%H:%M:%S`   
echo -e '\n'$kaishi ---------------------- Starting ---------------------- >>$file_name   
wget -4 --spider --quiet --tries=1 --timeout=3 www.google.co.jp  # Test connect google jp
if [ "$?" == "0" ]; then  
        DATE=`date +%Y-%m-%d-%H:%M:%S`
        echo  $DATE www.google.co.jp is OK  >>$file_name   # Connect google jp sucess mean shadowsocks is work right
        exit 0
else
        wget -4 --spider --quiet --tries=1 --timeout=3 www.baidu.com
        if [ "$?" == "0" ]; then
                /etc/init.d/shadowsocksr restart   # Connect baidu sucess mean shadowsocks is not work now,restart shadowsocks
                riqi=`date +%Y-%m-%d-%H:%M:%S`
                echo $riqi Problem decteted, restarting shadowsocksr.  >>$file_name  # Write event to the log
        else
                shijian=`date +%Y-%m-%d-%H:%M:%S`
                echo $shijian Network Problem. Plese check Network!!!!!!!  >>$file_name  # Local network problem
        fi
fi
