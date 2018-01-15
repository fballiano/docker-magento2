FROM ubuntu:16.04
MAINTAINER samuele@nutellino.it
# Installazione dei pacchetti necessari
RUN apt-get update
RUN apt-get -y install rsync cron mysql-client
# Add crontab file in the cron directory
ADD crontab_backup_magento2 /etc/cron.d/crontabcustom
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/crontabcustom

# Avvio del cron in modalità foreground
CMD ["cron", "-f"]