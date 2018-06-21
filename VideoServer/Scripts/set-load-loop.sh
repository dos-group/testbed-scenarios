#!/bin/bash
home=`dirname $(readlink -e $0)`

# Load bounderies in percent
MIN_LOAD=20
MAX_LOAD=90
CHANGE_INTERVAL_SECONDS=$(( 3*60 ))

while true; do
    target_load=$(( $MIN_LOAD + ( $RANDOM * ($MAX_LOAD - $MIN_LOAD) / 32767 ) ))
    echo "Loop: setting the load to $target_load%..."
    "$home/set-load.sh" $target_load
    echo "Waiting for $CHANGE_INTERVAL_SECONDS seconds..."
    sleep $CHANGE_INTERVAL_SECONDS
done
