#!/bin/sh
#dir=/home/suer/dropbear
dir=./
cd $dir
sudo rpm -e dropbear
sudo yum -y localinstall zlib* gcc make
sudo yum -y localinstall dev/*
[[ ! -d dropbear-2019.78 ]]&&tar -zxvf dropbear-2019.78.tar.gz
cd dropbear-2019.78
./configure
sudo make 
sudo make scp && sudo make install
sudo mkdir /etc/dropbear
cd ..
#cd .. && rm -rf dropbear-2019.78
sudo /usr/local/bin/dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
sudo /usr/local/bin/dropbearkey -t rsa -s 4096 -f /etc/dropbear/dropbear_rsa_host_key
sudo sh -c "echo 'port=2222' >/etc/sysconfig/dropbear "  
sudo /bin/cp -f dropbear /etc/rc.d/init.d/dropbear 
sudo chmod +x /etc/rc.d/init.d/dropbear  
sudo service dropbear start
sudo service dropbear status
