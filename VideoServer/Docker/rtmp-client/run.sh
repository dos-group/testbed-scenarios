#!/bin/bash

if [ -z "$MRL" ]; then
	if [ -z "$MRL_SERVER" ]; then
		echo "Please set the MRL_SERVER environment variable"
		exit 1
	fi
	test -z "$MRL_PORT" && MRL_PORT="1935"
	test -z "$MRL_PATH" && MRL_PATH="/vod/example.flv"
	test -z "$MRL_PROTO" && MRL_PROTO="rtmp"
	MRL="$MRL_PROTO://$MRL_SERVER:$MRL_PORT$MRL_PATH"
fi

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

for i in $(seq $PARALLEL); do
	# Spawn parallel subshell(s)
	(
		i=1
		while $INFINITE || [ $i -le $LOOP ]; do
			if $INFINITE; then
				echo "Running ffmpeg $i in infinite loop..."
			else
				echo "Running ffmpeg $i of $LOOP..."
			fi
			i=$((i+1))
			ffmpeg -i "$MRL" -f null /dev/null -loglevel 23 -stats $@ </dev/null || break
		done
	)&
done

wait
