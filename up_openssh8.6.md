此脚本为离线环境准备
- 1.下载openssh8.6源码包，[镜像地址](https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/)
- 2.yum downloadonly下载pam-devel以及依赖，gcc以及依赖。
- 3.OpenSSL版本为1.0.2k,系统版本为centOS7.*
- 4.网上他人编译的rpm包所依赖的OpenSSL不一定是1.0.2k，所以rpm -Uvh 升级openssh可能会出现ssh -V和openssl version显示OpenSSL版本不一致的情况
```
#!/bin/sh
#yilai和gcc为离线rpm包目录
yum localinstall -y  yilai/pam* --skip-broken
cd gcc
yum localinstall -y gcc* --skip-broken
cd ../
[[ ! -d openssh-8.6p1 ]]&& tar -zxvf openssh-8.6p1.tar.gz
cd  openssh-8.6p1
./configure --prefix=/usr --sysconfdir=/etc/ssh --with-zlib --without-openssl-header-check --with-ssl-dir=/usr/local --with-privsep-path=/var/lib/sshd --with-pam
make&&make install
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
cp -a contrib/redhat/sshd.init /etc/init.d/sshd
cp -a contrib/redhat/sshd.pam /etc/pam.d/sshd.pam
chmod +x /etc/init.d/sshd
chmod 600 /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key 
sed -i 's/GSSAPIAuthentication no/#GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/GSSAPICleanupCredentials no/#GSSAPICleanupCredentials no/' /etc/ssh/sshd_config
sed -i '/PermitRootLogin no/d' /etc/ssh/sshd_config
mv /etc/pam.d/sshd /etc/pam.d/sshd.bak
#下面的/etc/pam.d/sshd 如果不修改，那/etc/ssh/sshd_config里的UsePam yes得改为no或者删除，不然密码无法登陆。
cat >/etc/pam.d/sshd <<EOF
#%PAM-1.0
auth       required     pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
EOF
chkconfig --add sshd
systemctl enable sshd
systemctl restart sshd
```
