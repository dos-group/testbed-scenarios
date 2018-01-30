# hub.docker.com/r/antongulenko/rtmp-haproxy-balancer
FROM haproxy
COPY rtmp-balancer-entrypoint.sh /rtmp-balancer-entrypoint.sh
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
ENTRYPOINT ["/rtmp-balancer-entrypoint.sh", "haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
