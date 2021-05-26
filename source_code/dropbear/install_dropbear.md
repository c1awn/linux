此脚本为离线环境准备
- yum安装的dropbear残缺，还是编译安装靠谱点
```
#!/bin/sh
dir=./
cd $dir
sudo rpm -e dropbear
#提前下载依赖包，其中开发组包用yumdownloader "@Development Tools" --resolve --destdir  yourdir
# 安装yumdownloader 用yum install yum-utils
sudo yum -y localinstall zlib/* gcc/* make/* --skip-broken
sudo yum -y localinstall dev/* --skip-broken
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
```