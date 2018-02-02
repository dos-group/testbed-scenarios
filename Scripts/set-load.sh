#!/bin/bash
home=`dirname $(readlink -e $0)`

test $# = 1 || { echo "Need 1 parameter: target load [0..100]"; exit 1; }
PERCENT_LOAD="$1"

LOAD_ENABLED="$home/enabled"
LOAD_DISABLED="$home/disabled"
ROOT="$home/all"

mapfile -t allfiles <<< $(find "$ROOT" -type f | shuf)
num_files=${#allfiles[*]}
target_enabled_files=$(( ( $PERCENT_LOAD * $num_files ) / 100 )) # TODO Unfortunately this always rounds down
echo "Going to enable $target_enabled_files of $num_files files"
already_enabled_files=0

for file in ${allfiles[*]}; do
  if [ "$already_enabled_files" -lt "$target_enabled_files" ]; then
    echo "Enabling: $file"
    cp "$LOAD_ENABLED" "$file"
    already_enabled_files=$((already_enabled_files + 1))
  else
    echo "Disabling: $file"
    cp "$LOAD_DISABLED" "$file"
  fi
done
