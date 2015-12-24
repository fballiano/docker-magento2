# Magento2 (Varnish + PHP7 + Redis) docker-compose infrastructure

## Infrastructure overview
* Container 1: MariaDB
* Container 2: Redis (we'll use it for Magento's cache)
* Container 3: Apache 2.4 + PHP 7 (modphp)
* Container 4: Cron
* Container 5: Varnish 4

###Why a separate cron container?
First of all containers should be (as far as possible) single process, but the most important thing is that (if someday we'll be able to deploy this infrastructure in production) we may need a cluster of apache+php containers but a single cron container running.

Plus, with this separation, in the context of a docker swarm, you may be able in the future to separare resources allocated to the cron container from the rest of the infrastructure.

## Downloading Magento2
```
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition magento2
```

## Starting all docker containers
```
docker-compose up -d
```
The fist time you run this command it's gonna take some time to download all the required images from docker hub.

## Do you want sample data?
First we need to enter the apache+php container:
```
docker exec -it dockermagento2_apache_1 bash
```

Then execute (from within the container):
```
php bin/magento sampledata:deploy
```

## Install Magento2

still writing
