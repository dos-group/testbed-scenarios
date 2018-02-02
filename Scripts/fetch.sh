#!/bin/bash
# Fetch the monitoring data currently available at all virtual and physical hosts.
# Creates a new folder (with current timestamp) for the data.
# The remote data will NOT be deleted. Calling this script multiple times will fetch the same data, but the second dataset might contain additional data.
home=`dirname $(readlink -e $0)`

source "$home/hosts-video-on-demand.sh"

remote_files="/opt/bitflow/data-collector/data*.bin"
target_dir="$home/fetched_data"

# Look for a number-prefix that does not exist in the target folder
NUM=1
PREFIX=""
while true; do
    PREFIX="$(printf "%.2d" $NUM)_"
    if find "$target_dir" -maxdepth 1 -mindepth 1 -name "$PREFIX*" | egrep '.*' &> /dev/null; then
        NUM=$((NUM+1))
    else
        break
    fi
done

folder="$target_dir/$PREFIX$(date '+%F_%H-%M-%S')/0-raw"
echo "Fetching data into $folder"

for i in $all_core_hosts; do
    echo " >>> Fetching from $i ..."
    target="$folder/$i"
    mkdir -p "$target"
    scp "$i:$remote_files" "$target"
done

