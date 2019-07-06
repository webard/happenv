cd /usr/lib/happenv
git pull
chmod 700 -R /usr/lib/happenv
rm /usr/bin/happenv
ln -s /usr/lib/happenv/action.sh /usr/bin/happenv
rm /etc/systemd/system/happenv.service
ln -s /usr/lib/happenv/happenv.service /etc/systemd/system/happenv.service
service happenv reenable
service happenv restart