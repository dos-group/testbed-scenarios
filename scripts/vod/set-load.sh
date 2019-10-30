#!/bin/bash
home=`dirname $(readlink -e $0)`

MAX_STREAMS_PER_CLIENT=80

test $# = 1 || { echo "Need 1 parameter: target load, integer in [0..100]"; exit 1; }
PERCENT_LOAD="$1"

num_streams="$(( $MAX_STREAMS_PER_CLIENT * $PERCENT_LOAD / 100 ))"
test -z "$num_streams" && { echo "Failed to compute the number of streams per client. The parameter for this script must be an integer value."; exit 1; }

echo "Setting the RTMP streams on all clients to $num_streams"
cd "$home"
"$home/set-rtmp-streams.yml" -e NUM_RTMP_STREAMS=$num_streams

