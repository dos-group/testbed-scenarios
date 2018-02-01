#!/bin/bash

function read_mrl_batch_file() {
	test -r "$MRL_BATCH_FILE" || { echo "Could not read MRL targets from file $MRL_BATCH_FILE"; return 1; }

	unset MRL_BATCH_TARGETS # Clear the array
	mapfile -t MRL_BATCH_TARGETS < "$MRL_BATCH_FILE"

	test "${#MRL_BATCH_TARGETS[*]}" -gt 0 || { echo "No MRL targets defined in file $MRL_BATCH_FILE"; return 1; }
	echo "Loaded ${#MRL_BATCH_TARGETS[*]} MRL target(s) from $MRL_BATCH_FILE"
}

if [ -n "$MRL_BATCH_FILE" ]; then
	read_mrl_batch_file || exit 1
else
	if [ -z "$MRL" ]; then
		if [ -z "$MRL_SERVER" ]; then
			echo "Please set the MRL or MRL_SERVER environment variable"
			exit 1
		fi
		test -z "$MRL_PORT" && MRL_PORT="1935"
		test -z "$MRL_PATH" && MRL_PATH="/vod/example-11s.flv"
		test -z "$MRL_PROTO" && MRL_PROTO="rtmp"
		for s in $MRL_SERVER; do
			MRL="$MRL\n$MRL_PROTO://$s:$MRL_PORT$MRL_PATH"
		done
	fi
	mapfile -t MRL_BATCH_TARGETS <<< $(echo -e "$MRL")
fi

test -z "$MRL_LOG" && MRL_LOG=/tmp/rtmp.log
touch $MRL_LOG

# Check if LOOP is a valid number
test -z "$LOOP" && LOOP=1
test "$LOOP" -eq "$LOOP" &> /dev/null || { echo "Warning: invalid LOOP variable '$LOOP'. Using 1."; LOOP=1; }
test $LOOP -le 0 && INFINITE=true || INFINITE=false

i=1
ffmpeg_num=1
while $INFINITE || [ $i -le $LOOP ]; do
	test -n "$MRL_BATCH_FILE" && read_mrl_batch_file # Update targets to allow live changes
	INDEX=$(($i % ${#MRL_BATCH_TARGETS[*]}))
	MRL_TARGET="${MRL_BATCH_TARGETS[$INDEX]}"

	if $INFINITE; then
		echo "Running ffmpeg $ffmpeg_num in infinite loop loading $MRL_TARGET..."
	else
		echo "Running ffmpeg $ffmpeg_num of $LOOP loading $MRL_TARGET..."
	fi

	# Execute the actual ffmpeg process. Loglevel 23 outputs performance statistics, errors and nothing else.
	# Pipe the output to the logfile, do not output the video anywhere.
	ffmpeg -i "$MRL_TARGET" -f null /dev/null -loglevel 23 -stats $@ &>> "$MRL_LOG" </dev/null

	sleep 1 || exit 0 # Allow user to end this loop with CTRL-C
	ffmpeg_num=$((ffmpeg_num+1))
	i=$((i+1))
done
