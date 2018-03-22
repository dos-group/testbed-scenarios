#!/bin/bash
home=`dirname $(readlink -e $0)`

test $# = 1 || { echo "Need 1 parameter: target load [0..100]"; exit 1; }
PERCENT_LOAD="$1"

LOAD_ENABLED="$home/rtmp-client-targets-templates/rtmp-client-targets-enabled-balancers-720p.txt"
LOAD_DISABLED="$home/rtmp-client-targets-templates/rtmp-client-targets-disabled.txt"
ROOT="$home/rtmp-client-targets"

allfiles=$(find "$ROOT" -type f | shuf)
num_files=$(echo "$allfiles" | wc -l)
target_enabled_files=$(( ( $PERCENT_LOAD * $num_files ) / 100 )) # TODO Unfortunately this always rounds down
echo "Enabling $target_enabled_files of $num_files video stream clients"
already_enabled_files=0

for file in $allfiles; do
  if [ "$already_enabled_files" -lt "$target_enabled_files" ]; then
    cp "$LOAD_ENABLED" "$file"
    already_enabled_files=$((already_enabled_files + 1))
  else
    cp "$LOAD_DISABLED" "$file"
  fi
done

ansible-playbook -i "$home/../Ansible/ansible-inventory.ini"  "$home/update-client-targets.yml"
echo "Killing ffmpeg processes..."
ansible -i "$home/../Ansible/ansible-inventory.ini" client -b -m shell -a 'killall ffmpeg'

