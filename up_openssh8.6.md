此脚本为离线环境准备
- 1.下载openssh8.6源码包，[镜像地址](https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/)
- 2.yum downloadonly下载pam-devel以及依赖，gcc以及依赖。
- 3.本地验证环境：Openssh为8.*，OpenSSL版本为1.0.2k,系统版本为centOS7.*
- 4.如果系统版本为centOS7.*，但是Openssh为7.*，需要在make和make install直接加一句卸载7.*。虽然服务总体看着正常，有一点bug:如果使用restart会有Can't open PID file /var/run/sshd.pid (yet?) after start: No such file or directory的报错，不影响服务，先stop再start则不会有此报错。[Redhat关于此bug的链接](https://bugzilla.redhat.com/show_bug.cgi?id=1381997)
- 4.网上他人编译的rpm包所依赖的OpenSSL不一定是1.0.2k，所以rpm -Uvh 升级openssh可能会出现ssh -V和openssl version显示OpenSSL版本不一致的情况
```
#!/bin/sh
#root权限操作此脚本
#备份ssh:
mv /etc/ssh /etc/sshbak
mv /usr/bin/ssh /usr/bin/sshbak
mv /usr/sbin/sshd /usr/sbin/sshdbak
mv /etc/pam.d/sshd /etc/pam.d/sshdbak
#yilai和gcc为离线rpm包目录
yum localinstall -y  yilai/pam* --skip-broken
cd gcc
yum localinstall -y gcc* --skip-broken
cd ../
[[ ! -d openssh-8.6p1 ]]&& tar -zxvf openssh-8.6p1.tar.gz
cd  openssh-8.6p1
./configure --prefix=/usr --sysconfdir=/etc/ssh --with-zlib --without-openssl-header-check --with-ssl-dir=/usr/local --with-privsep-path=/var/lib/sshd --with-pam
make
#如果openssh初始为7.*，需要卸载，不然sshd无法正常启动。
rpm -qa|grep openssh|grep openssh-7.
[[ $? -eq 0 ]]&&rpm -e --nodeps `rpm -qa | grep openssh`
make install
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
cp -a contrib/redhat/sshd.init /etc/init.d/sshd
cp -a contrib/redhat/sshd.pam /etc/pam.d/sshd.pam
chmod +x /etc/init.d/sshd
chmod 600 /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key 
sed -i 's/GSSAPIAuthentication no/#GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/GSSAPICleanupCredentials no/#GSSAPICleanupCredentials no/' /etc/ssh/sshd_config
sed -i '/PermitRootLogin no/d' /etc/ssh/sshd_config
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
