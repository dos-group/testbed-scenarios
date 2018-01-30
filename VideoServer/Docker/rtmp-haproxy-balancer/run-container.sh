#!/bin/bash

PORT1="$RTMP_PORT"
test -z "$PORT1" && PORT1=1935
PORT2="$STATS_PORT"
test -z "$PORT2" && PORT2=8888

docker run $@ \
    -e "RTMP_PORT=$RTMP_PORT" \
    -e "STATS_PORT=$STATS_PORT" \
    -e "RTMP_SERVERS=$RTMP_SERVERS" \
    -p "$PORT1:$PORT1" \
    -p "$PORT2:$PORT2" \
    -ti antongulenko/rtmp-haproxy-balancer
