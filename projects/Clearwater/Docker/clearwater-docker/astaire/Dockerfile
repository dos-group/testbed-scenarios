FROM clearwater/base
MAINTAINER maintainers@projectclearwater.org


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes clearwater-memcached
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes astaire
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes rogers

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes jq

COPY scale_astaire.sh /usr/share/clearwater/bin/scale_astaire.sh
COPY crontab /etc/cron.d/
RUN chmod +x /usr/share/clearwater/bin/scale_astaire.sh && chmod 0600 /etc/cron.d/crontab 
RUN touch /var/log/scale-astaire.log


COPY memcached.supervisord.conf /etc/supervisor/conf.d/memcached.conf
COPY astaire.supervisord.conf /etc/supervisor/conf.d/astaire.conf
COPY cron.supervisord.conf /etc/supervisor/conf.d/cron.conf
COPY rogers.supervisord.conf /etc/supervisor/conf.d/rogers.conf
COPY clearwater-group.supervisord.conf /etc/supervisor/conf.d/clearwater-group.conf

EXPOSE 11311



