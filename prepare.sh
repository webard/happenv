#!/bin/bash
mkdir /var/www
mv /var/lib/mysql /var/lib/mysql.old
mv /etc/mysql /etc/mysql.old
apt update
mypass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
apt dist-upgrade -yqq
apt install ca-certificates apt-transport-https dirmngr -yqq
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
curl -L https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 5072E1F5
apt-key adv --keyserver keys.ubuntu.com --recv-keys 5072E1F5
echo "deb http://repo.mysql.com/apt/debian $(lsb_release -sc) mysql-8.0" | sudo tee /etc/apt/sources.list.d/mysql80.list
echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
cat <<EOF >> /etc/apt/sources.list.d/nginx.list
deb http://nginx.org/packages/debian/ stretch nginx
deb-src http://nginx.org/packages/debian/ stretch nginx
EOF
apt update
apt dist-upgrade -yqq
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password "$mypass
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password "$mypass
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"
apt update
DEBIAN_FRONTEND=noninteractive apt install mysql-server -yqq
apt install htop php7.2-fpm php7.2-cli php7.2-common php7.2-curl php7.2-mbstring php7.2-mysql php7.2-xml nginx dirmngr -yqq
mkdir /etc/nginx/sites-enabled
mkdir /etc/nginx/sites-available
cat <<EOF >> /etc/mysql/conf.d/sylapi.cnf
[mysqld]
sql-mode="STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
character-set-server=utf8mb4
default_authentication_plugin=mysql_native_password
EOF
sed -i -e 's/include \/etc\/nginx\/conf\.d\/\*\.conf\;/include \/etc\/nginx\/conf\.d\/\*\.conf\;\'$'\n    include \/etc\/nginx\/sites\-enabled\/\*\.conf\;/g' /etc/nginx/nginx.conf
service nginx restart
service mysql restart
mysql -uroot -p$mypass -e "use mysql;CREATE USER 'oozaru'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_OOZARU_PASSWORD';GRANT ALL ON *.* TO 'oozaru'@'localhost';flush privileges;"