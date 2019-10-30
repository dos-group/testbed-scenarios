FROM clearwater/base
MAINTAINER maintainers@projectclearwater.org


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes mysql-server && find /var/lib/mysql -type f -exec touch {} \; && service mysql start
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes ellis && /usr/sbin/dnsmasq --interface=lo --user=root 
RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start
# RUN /etc/init.d/mysql start


COPY create_numbers.sh /usr/share/clearwater/ellis/create_numbers.sh
COPY ellis.supervisord.conf /etc/supervisor/conf.d/ellis.conf
COPY mysql.supervisord.conf /etc/supervisor/conf.d/mysql.conf
COPY initsql.supervisord.conf /etc/supervisor/conf.d/initsql.conf
COPY nginx.supervisord.conf /etc/supervisor/conf.d/nginx.conf
COPY clearwater-group.supervisord.conf /etc/supervisor/conf.d/clearwater-group.conf

RUN find /var/lib/mysql -type f -exec touch {} \; && service mysql start && /usr/share/clearwater/ellis/create_numbers.sh

EXPOSE 80


