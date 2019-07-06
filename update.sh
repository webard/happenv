#!/bin/bash
cd /usr/lib/happenv
git pull
chmod 700 -R /usr/lib/happenv
rm /usr/bin/happenv-admin
ln -s /usr/lib/happenv/admin.sh /usr/bin/happenv-admin
rm /etc/systemd/system/happenv-admin.service
ln -s /usr/lib/happenv/happenv-admin.service /etc/systemd/system/happenv-admin.service
systemctl daemon-reload
systemctl enable happenv-admin
systemctl restart happenv-admin