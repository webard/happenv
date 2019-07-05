#!/bin/bash
apt update
apt dist-upgrade -yqq
mkdir /home/admin/.ssh
chmod 0700 /home/admin/.ssh
cat <<EOF >> /root/.ssh/authorized_keys
ADDCESS PUB HERE
EOF
chmod 0600 /home/admin/.ssh/authorized_keys
 
mkdir /root/.ssh
chmod 0700 /root/.ssh
cat <<EOF >> /root/.ssh/id_rsa.pub
PUB CERT HERE
EOF
cat <<EOF >> /root/.ssh/id_rsa
PRIV CERT HERE
EOF
chmod 0600 -R /root/.ssh
apt install git -yqq
if [ ! -n "$(grep "^github.com " /root/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null; fi
git clone git@github.com:webard/sylaunch.git /root/sylaunch
chmod 700 -R /root/sylaunch
ln -s /root/sylaunch/launch.sh /usr/bin/sylaunch 
bash /root/sylaunch/prepare.sh