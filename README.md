# Docker Magento2: Varnish 6 + PHP7.4 + Redis + Elasticsearch 7.6 + SSL cluster ready docker-compose infrastructure

## Infrastructure overview
* Container 1: MariaDB
* Container 2: Redis (volatile, for Magento's cache)
* Container 3: Redis (for Magento's sessions)
* Container 4: Apache 2.4 + PHP 7.4 (modphp)
* Container 5: Cron
* Container 6: Varnish 6
* Container 7: Redis (volatile, cluster nodes autodiscovery)
* Container 8: Nginx SSL terminator
* Container 9: Elasticsearch 7.6

### Why a separate cron container?
First of all containers should be (as far as possible) single process, but the most important thing is that (if someday we'll be able to deploy this infrastructure in production) we may need a cluster of apache+php containers but a single cron container running.

Plus, with this separation, in the context of a docker swarm, you may be able in the future to separare resources allocated to the cron container from the rest of the infrastructure.

## Setup Magento 2

Download Magento 2 in any way you want (zip/tgz from website, composer, etc) and extract in the "magento2" subdirectory of this project.

If you want to change the default "magento2" directory simply change its name in the "docker-compose.yml" (there are 2 references, under the "cron" section and under the "apache" section).

## Starting all docker containers
```
docker-compose up -d
```
The fist time you run this command it's gonna take some time to download all the required images from docker hub.

## Install Magento2

### Method 1: CLI
```
docker exec -it docker-magento2_apache_1 bash
php bin/magento setup:install \
  --db-host docker-magento2_db_1 --db-name magento2 --db-user magento2 --db-password magento2  --admin-user admin --timezone 'Europe/Rome' --currency EUR --use-rewrites 1 --cleanup-database \
  --backend-frontname admin --admin-firstname AdminFirstName --admin-lastname AdminLastName --admin-email 'admin@email.com' --admin-password 'ChangeThisPassword1' --base-url 'https://magento2.docker/' --language en_US \
  --session-save=redis --session-save-redis-host=sessions --session-save-redis-port=6379 --session-save-redis-db=0 --session-save-redis-password='' \
  --cache-backend=redis --cache-backend-redis-server=cache --cache-backend-redis-port=6379 --cache-backend-redis-db=0 \
  --page-cache=redis --page-cache-redis-server=cache --page-cache-redis-port=6379 --page-cache-redis-db=1 \
  --search-engine=elasticsearch7 --elasticsearch-host=elasticsearch
```

### Method 2: Web installer

If you want to install Magento via web installer (not the best option, it will probably timeout) open your browser to the address:
```
https://magento2.docker/
```
and use the wizard to install Magento2.  
For database configuration use hostname db (or the name assigned to the DB container in your `docker-compose.yml` file, default is docker-magento2_db_1), and username/password/dbname you have in your docker-compose.xml file, defaults are:
- MYSQL_USER=magento2
- MYSQL_PASSWORD=magento2
- MYSQL_DATABASE=magento2

## Deploy static files
```
docker exec -it docker-magento2_apache_1 bash
php bin/magento dev:source-theme:deploy
php bin/magento setup:static-content:deploy
```

## Enable Redis for Magento's cache
If you installed Magento via CLI then Redis is already configured, otherwise open magento2/app/etc/env.php and add these lines:
```php
'cache' => [
  'frontend' => [
    'default' => [
      'backend' => 'Cm_Cache_Backend_Redis',
      'backend_options' => [
        'server' => 'cache',
        'port' => '6379',
        'persistent' => '', // Specify a unique string like "cache-db0" to enable persistent connections.
        'database' => '0',
        'password' => '',
        'force_standalone' => '0', // 0 for phpredis, 1 for standalone PHP
        'connect_retries' => '1', // Reduces errors due to random connection failures
        'read_timeout' => '10', // Set read timeout duration
        'automatic_cleaning_factor' => '0', // Disabled by default
        'compress_data' => '1', // 0-9 for compression level, recommended: 0 or 1
        'compress_tags' => '1', // 0-9 for compression level, recommended: 0 or 1
        'compress_threshold' => '20480', // Strings below this size will not be compressed
        'compression_lib' => 'gzip', // Supports gzip, lzf and snappy,
        'use_lua' => '0' // Lua scripts should be used for some operations
      ]
    ],
    'page_cache' => [
      'backend' => 'Cm_Cache_Backend_Redis',
      'backend_options' => [
        'server' => 'cache',
        'port' => '6379',
        'persistent' => '', // Specify a unique string like "cache-db0" to enable persistent connections.
        'database' => '1', // Separate database 1 to keep FPC separately
        'password' => '',
        'force_standalone' => '0', // 0 for phpredis, 1 for standalone PHP
        'connect_retries' => '1', // Reduces errors due to random connection failures
        'lifetimelimit' => '57600', // 16 hours of lifetime for cache record
        'compress_data' => '0' // DISABLE compression for EE FPC since it already uses compression
      ]
    ]
  ]
],
```
and delete all Magento's cache with
```
rm -rf magento2/var/cache/*
```
from now on the var/cache directory should stay empty cause all the caches should be stored in Redis.

## Enable Redis for Magento's sessions
If you installed Magento via CLI then Redis is already configured, otherwise open magento2/app/etc/env.php and replace these lines:
```php
'session' => [
  'save' => 'files',
],
```

with these ones:

```php
'session' => [
  'save' => 'redis',
  'redis' => [
    'host' => 'sessions',
    'port' => '6379',
    'password' => '',
    'timeout' => '2.5',
    'persistent_identifier' => '',
    'database' => '0',
    'compression_threshold' => '2048',
    'compression_library' => 'gzip',
    'log_level' => '3',
    'max_concurrency' => '6',
    'break_after_frontend' => '5',
    'break_after_adminhtml' => '30',
    'first_lifetime' => '600',
    'bot_first_lifetime' => '60',
    'bot_lifetime' => '7200',
    'disable_locking' => '0',
    'min_lifetime' => '60',
    'max_lifetime' => '2592000'
  ]
],
```
and delete old Magento's sessions with
```
rm -rf magento2/var/session/*
```

## Enable Varnish
Varnish Full Page Cache should already be enabled out of the box (we startup Varnish with the default VCL file generated by Magento2) but you could anyway go to "stores -> configuration -> advanced -> system -> full page cache" and:
* select Varnish in the "caching application" combobox
* type "apache" in both "access list" and "backend host" fields
* type 80 in the "backend port" field
* save

Configure Magento to purge Varnish:

```
docker exec -it docker-magento2_apache_1 bash
php bin/magento setup:config:set --http-cache-hosts=varnish
```

https://devdocs.magento.com/guides/v2.3/config-guide/varnish/use-varnish-cache.html

## Enable SSL Support
Add this line to magento2/.htaccess
```
SetEnvIf X-Forwarded-Proto https HTTPS=on
```
Then you can configure Magento as you wish to support secure urls.

If you need to generate new self signed certificates use this command
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
```
then you can mount them into the nginx-ssl container using the "volumes" instruction in the docker-compose.xml file. Same thing goes if you need to use custom nginx configurations (you can mount them into /etc/nginx/conf.d). Check the source code of https://github.com/fballiano/docker-nginx-ssl-for-magento2 to better understand where are the configuration stored inside the image/container.

## Scaling apache containers
If you need more horsepower you can
```
docker-compose scale apache=X
```
where X is the number of apache containers you want.

The cron container will check how many apache containers we have (broadcast/discovery service is stored on the redis_clusterdata container) and will update Varnish's VCL.

You can start your system with just one apache container, then scale it afterward, autodiscovery will reconfigure the load balancing on the fly.

Also, the cron container (which updates Varnish's VCL) sets a "probe" to "/fb_host_probe.txt" every 5 seconds, if 1 fails (container has been shut down) the container is considered sick.

## Custom php.ini
We already have a personalized php.ini inside this project: https://github.com/fballiano/docker-magento2-apache-php/blob/master/php.ini but if you want to further customize your settings:
- edit the php.ini file in the root directoy of this project
- edit the "docker-compose.xml" file, look for the 2 commented lines (under the "cron" section and under the "apache" section) referencing the php.ini
- start/restart the docker stack

Please note that your php.ini will be the last parsed thus you can ovverride any setting.

## Tested on:
* Docker for Mac 19

## TODO
* DB clustering?
* RabbitMQ?
let me know what features would you like to see implemented.

## Changelog:
* 2020-09-19:
  * Magento 2.4 branch added
  * Elasticsearch container added for Magento 2.4
  * Upaded all dependencies
* 2020-03-18:
  * added "sockets" PHP extension to docker-apache-php image
  * fixed some typos/mistakes in the README
  * added CLI install to the README
  * refactored some parts of the documentation to better use magento's CLI
* 2019-08-09:
  * small bugfix in varnishadm.sh and varnishncsa.sh scripts
* 2019-08-06:
  * new redis sessions container was added
* 2019-08-05:
  * migrated to docker-compose syntax 3.7
  * implemented "delegated" consistency for some of volumes for a better performance
  * varnish.vcl was regenerated for Varnish 5 (which was already used since some months)
