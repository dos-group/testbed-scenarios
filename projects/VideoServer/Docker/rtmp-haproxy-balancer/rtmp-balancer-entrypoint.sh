#!/bin/bash

test -z "$RTMP_PORT" && RTMP_PORT=1935
test -z "$STATS_PORT" && STATS_PORT=8888
test -z "$RTMP_SERVERS" && { echo "Variable RTMP_SERVERS is not defined."; exit 1; }

BACKENDS=""
for i in $RTMP_SERVERS; do
  BACKENDS="$BACKENDS\\nserver $i $i:$RTMP_PORT check"
done

# Fix the haproxy.cfg based on some environment variables
sed -i "/usr/local/etc/haproxy/haproxy.cfg" \
  -e "s/__RTMP_PORT__/$RTMP_PORT/g" \
  -e "s/__STATS_PORT__/$STATS_PORT/g" \
  -e "s#__RTMP_SERVERS__#$BACKENDS#g" \

# Continue with the default entrypoint of the upstream haproxy image
/docker-entrypoint.sh $@
