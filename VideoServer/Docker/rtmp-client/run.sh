#!/bin/bash

if [ -z "$MRL" ]; then
	if [ -z "$MRL_SERVER" ]; then
		echo "Please set the MRL or MRL_SERVER environment variable"
		exit 1
	fi
	test -z "$MRL_PORT" && MRL_PORT="1935"
	test -z "$MRL_PATH" && MRL_PATH="/vod/example-11s.flv"
	test -z "$MRL_PROTO" && MRL_PROTO="rtmp"
	for s in $MRL_SERVER; do
		MRL="$MRL $MRL_PROTO://$s:$MRL_PORT$MRL_PATH"
	done
fi

test -z "$MRL_LOG" && MRL_LOG=/tmp/rtmp.log
touch $MRL_LOG

# Check if LOOP is a valid number
test -z "$LOOP" && LOOP=1
test "$LOOP" -eq "$LOOP" &> /dev/null || { echo "Warning: invalid LOOP variable '$LOOP'. Using 1."; LOOP=1; }
test $LOOP -le 0 && INFINITE=true || INFINITE=false

# Check if PARALLEL is a valid number
test -z "$PARALLEL" && PARALLEL=1
if ! [ "$PARALLEL" -eq "$PARALLEL" -a "$PARALLEL" -gt 0 ] &> /dev/null; then
		echo "Warning: invalid PARALLEL variable '$PARALLEL'. Using 1."
		PARALLEL=1
fi

function loop_ffmpeg() {
	i=1
	ffmpeg_num=1
	while $INFINITE || [ $i -le $LOOP ]; do
		for ONE_MRL in $MRL; do
			if $INFINITE; then
				echo "Running ffmpeg $ffmpeg_num in infinite loop loading $ONE_MRL..."
			else
				echo "Running ffmpeg $ffmpeg_num of $LOOP loading $ONE_MRL..."
			fi
			ffmpeg_num=$((ffmpeg_num+1))
			ffmpeg -i "$ONE_MRL" -f null /dev/null -loglevel 23 -stats $@ &>> "$MRL_LOG" </dev/null || return
		done
		i=$((i+1))
	done
}

for i in $(seq $PARALLEL); do
	# Spawn parallel subshell(s)
	loop_ffmpeg &
done

tail -f "$MRL_LOG"
wait
