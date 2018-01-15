#!/usr/bin/env bash
echo 'Fix permissions start'
find . -type f -exec chmod 644 {} \;
echo 'Completed 10%'
find . -type d -exec chmod 755 {} \;
echo 'Completed 20%'
find ./var -type d -exec chmod 777 {} \;
echo 'Completed 30%'
find ./pub/media -type d -exec chmod 777 {} \;
echo 'Completed 40%'
find ./pub/static -type d -exec chmod 777 {} \;
echo 'Completed 50%'
chmod 777 ./app/etc
echo 'Completed 60%'
chmod 644 ./app/etc/*.xml
echo 'Completed 70%'
chown -R www-data:www-data .
echo 'Completed 80%'
chmod u+x bin/magento
echo 'Completed 90%'
chmod u+x fix_permissions.sh
chmod 777 .gitignore
echo 'Completed 100%'