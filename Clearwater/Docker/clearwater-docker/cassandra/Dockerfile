FROM clearwater/base
MAINTAINER maintainers@projectclearwater.org


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes homestead-cassandra homestead-prov-cassandra homer-cassandra
RUN sed -e 's/-c cassandra/-c root/g' -i /etc/init.d/cassandra

COPY start_cassandra.sh /usr/bin/start_cassandra.sh

COPY scale_down.sh /usr/share/clearwater/bin/scale_down.sh

COPY crontab /etc/cron.d/

RUN chmod +x /usr/share/clearwater/bin/scale_down.sh && chmod 0600 /etc/cron.d/crontab 
RUN touch /var/log/scale-down-cassandra.log

COPY cassandra.supervisord.conf /etc/supervisor/conf.d/cassandra.conf
COPY cron.supervisord.conf /etc/supervisor/conf.d/cron.conf
COPY clearwater-group.supervisord.conf /etc/supervisor/conf.d/clearwater-group.conf

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes jq

EXPOSE 9160 7001 7001 9042

RUN sed -i "s/rpc_address: ::0/rpc_address: 0.0.0.0/" /usr/share/clearwater/cassandra/cassandra.yaml.template