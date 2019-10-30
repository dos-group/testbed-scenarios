#!/bin/bash
home=`dirname $(readlink -e $0)`

FETCH_DIR="$HOME/fetched-data"
NUM=1

# Find a non-existing folder to fetch into
while [ -e "$FETCH_DIR/$NUM" ]; do NUM=$((NUM+1)); done
TARGET_DIR="$FETCH_DIR/$NUM"
mkdir -p "$TARGET_DIR"
echo "Fetching data to $TARGET_DIR"
"$home/fetch-data.yml" -e "fetch_dir=$TARGET_DIR"
#Delete all empty directories
find $TARGET_DIR -empty -type d -delete
