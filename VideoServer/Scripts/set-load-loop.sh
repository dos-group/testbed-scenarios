#!/bin/bash
home=`dirname $(readlink -e $0)`

# Load bounderies in percent
MIN_LOAD=20
MAX_LOAD=90
CHANGE_INTERVAL_SECONDS=$(( 10*60 ))

while true;
    target_load=...
    echo "Setting the load to $target_load%..."
    "$home/set-load.sh" $target_load
    echo "Waiting for $CHANGE_INTERVAL_SECONDS seconds..."
    sleep $CHANGE_INTERVAL_SECONDS
do
