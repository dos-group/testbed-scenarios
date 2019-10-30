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
			test -n "$MRL" && MRL="$MRL\n"
			MRL="$MRL$MRL_PROTO://$s:$MRL_PORT$MRL_PATH"
		done
	fi
	mapfile -t MRL_BATCH_TARGETS <<< $(echo -e "$MRL")
fi

if [ -n "$MRL_LOG" ]; then
	echo "Logging ffmpeg performance stats to file: $MRL_LOG"
elif [ -n "$MRL_LOG_DIR" ]; then
	echo "Logging ffmpeg performance stats to individual files in directory: $MRL_LOG_DIR"
	mkdir -p "$MRL_LOG_DIR"
else
	echo "Logging ffmpeg performance stats to standard output"
	MRL_LOG="/dev/stdout"
fi

# Check if LOOP is a valid number
test -z "$LOOP" && LOOP=1
test "$LOOP" -eq "$LOOP" &> /dev/null || { echo "Warning: invalid LOOP variable '$LOOP'. Using 1."; LOOP=1; }
test $LOOP -le 0 && INFINITE=true || INFINITE=false

test -z "$MRL_LOGFILE_PREFIX" && MRL_LOGFILE_PREFIX="rtmp-client-"
if [ -z "$MRL_BATCH_INDEX_OFFSET" ]; then
	MRL_BATCH_INDEX_OFFSET=0
elif [ "$MRL_BATCH_INDEX_OFFSET" -lt 0 ]; then
	# Allows randomizing the starting index inside the batch targets file, to create a more random load when using multiple clients
	MRL_BATCH_INDEX_OFFSET=$RANDOM
fi

i=1
ffmpeg_num=1
while $INFINITE || [ $i -le $LOOP ]; do
	test -n "$MRL_BATCH_FILE" && read_mrl_batch_file # Update targets to allow live changes
	INDEX=$((($MRL_BATCH_INDEX_OFFSET + $i) % ${#MRL_BATCH_TARGETS[*]}))
	MRL_TARGET="${MRL_BATCH_TARGETS[$INDEX]}"

	CURRENT_LOG="$MRL_LOG"
	if [ -z "$CURRENT_LOG" ]; then
		if [ -n "$MRL_LOG_DIR" ]; then
			CURRENT_LOG="$MRL_LOG_DIR/$MRL_LOGFILE_PREFIX$(date '+%Y-%m-%d.%H-%M-%S.%3N').log"
		else
			CURRENT_LOG="/dev/null" # Last resort to avoid syntax error
		fi
	fi

	if [[ "$MRL_TARGET" = CMD* ]]; then

		MRL_TARGET=${MRL_TARGET:3} # Strip the CMD prefix

		if $INFINITE; then
			echo "Running $MRL_TARGET (index $ffmpeg_num) in infinite loop..."
		else
			echo "Running $MRL_TARGET (index $ffmpeg_num) of $LOOP..."
		fi

		$MRL_TARGET

	else

		if $INFINITE; then
			echo "Running ffmpeg $ffmpeg_num in infinite loop loading $MRL_TARGET, logging to $CURRENT_LOG..."
		else
			echo "Running ffmpeg $ffmpeg_num of $LOOP loading $MRL_TARGET, logging to $CURRENT_LOG..."
		fi
		mkdir -p "$(dirname "$CURRENT_LOG")"

		# Execute the actual ffmpeg process. Loglevel 23 outputs performance statistics, errors and nothing else.
		# Pipe the output to the logfile, do not output the video anywhere.
		stdbuf -o128 -e128 \
			ffmpeg -i "$MRL_TARGET" -f null /dev/null -loglevel 23 -stats $@ </dev/null |& \
		stdbuf -i0 -eL -oL \
			tr "\r" "\n" &>> "$CURRENT_LOG"

		# ffmpeg outputs statistics on stderr, every entry is separated by \r instead of \n (\r clears the line for better experience on an interactive command line).
		# We want to receive every entry on a single line for easier processing, therefore we use the 'tr' command to translate \r into \n characters.
		# The 'tr' command introduces a pipe, and its output is redirected to a file, which affects the buffering behavior of both ffmpeg and tr.
		# In order to flush the output buffers immediately, 'stdbuf' is used to configure the buffers. For 'ffmpeg', the stdout and stderr buffer is chosen very small (128 bytes) to rapidly flush the statistics.
		# For tr, the output is buffered by line, because it introduces the regular \n line ending character.
	fi

	test $? = 255 -o $? = 130 && exit 0 # ffmpeg exits with code 255 after SIGINT
	sleep 1 || exit 0 # Allow user to end this loop with CTRL-C, if the above 'break' does not work
	ffmpeg_num=$((ffmpeg_num+1))
	i=$((i+1))
done
