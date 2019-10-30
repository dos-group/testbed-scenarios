#!/bin/bash

home=`dirname $(readlink -e $0)`

ANIBLE_DIR="$home/../../Scripts"

COLLECTOR_CSV_OUTPUT="$home/results/csv"
MAX_LOAD_NUM_CLIENTS="270" # Maximum number of clients. Capacity test will run until this number is reached.
LOAD_STEP_SIZE="10" # Step size to increase the load
TIMEOUT_BETWEEN_LOAD_INCR="300" # Seconds between load increments

ansible-playbook --forks=1 "$ANIBLE_DIR/create-endpoint-lists.yml"

declare -a collector_pids
declare -a client_pids

function run_downloader {
    for line in $(cat $1); do
        nohub $home/run_downloader.sh -s "${line##*#}" -f "$COLLECTOR_CSV_OUTPUT/${line%#*}.csv" &
        collector_pids+=($!)
    done
}

function check_pids_exist {
    for pid in ${collector_pids[@]}; do
        if ! kill -0 $pid > /dev/null 2>&1; then
            return 1
        fi
    done
    return 0
}

function kill_pids {
    for pid in ${1[@]}; do
        kill -9 $pid > /dev/null 2>&1
    done
}

ansible-playbook -e NUM_RTMP_STREAMS=0 "$ANIBLE_DIR/set-rtmp-streams.yml"

run_downloader "$home/collector-endpoints.txt"
run_downloader "$home/client-endpoints.txt"

sleep 30

check_pids_exist "${collector_pids[@]}"
if [ $? -ne 0 ]; then
    echo "Some collector download pipelines are missing. Exiting..."
    kill_pids "${collector_pids[@]}"
    kill_pids "${client_pids[@]}"
    return -1
fi

check_pids_exist "${client_pids[@]}"
if [ $? -ne 0 ]; then
    echo "Some client download pipelines are missing. Exiting..."
    kill_pids "${collector_pids[@]}"
    kill_pids "${client_pids[@]}"
    return -1
fi

for i in $(seq $LOAD_STEP_SIZE 10 $MAX_LOAD_NUM_CLIENTS); do 
    ansible-playbook -e NUM_RTMP_STREAMS=$i "$ANIBLE_DIR/set-rtmp-streams.yml"
    sleep $TIMEOUT_BETWEEN_LOAD_INCR
done

kill_pids "${collector_pids[@]}"
kill_pids "${client_pids[@]}"

for line in $(cat $1); do
    $home/run_collector_plotter.sh "$COLLECTOR_CSV_OUTPUT/${line%#*}.csv"
done

for line in $(cat $1); do
    $home/run_client_plotter.sh "$COLLECTOR_CSV_OUTPUT/${line%#*}.csv"
done





