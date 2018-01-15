#!/usr/bin/env bash
mysql -h db -N -uroot -pmagento2 -e 'show databases' | while read dbname; do mysqldump --single-transaction=TRUE -h db -uroot -pmagento2 --complete-insert  "$dbname" > /backup/"$dbname"_bck_`date +%Y%m%d`.sql; done
