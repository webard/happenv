apt update
apt dist-upgrade -yqq
mkdir ~/.ssh
chmod 0700 ~/.ssh
cat <<EOF >> ~/.ssh/id_rsa.pub
enter DD
EOF
cat <<EOF >> ~/.ssh/id_rsa
ENTER DD
EOF
chmod 0600 -R ~/.ssh
apt install git -yqq
if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi
git clone git@github.com:webard/sylaunch.git /root/sylaunch
chmod 700 -R /root/sylaunch
ln -s /root/sylaunch/launch.sh /usr/bin/sylaunch 
bash /root/sylaunch/prepare.sh