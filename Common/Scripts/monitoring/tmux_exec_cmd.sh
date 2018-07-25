#!/bin/bash

USAGE="$(basename "$0") [-h] [-i] [-n|--number-split] [-c|--command] [--ihost] [TARGETS] -- programm connects to remote hosts via ssh (one intermediate host connection possible) and optionally executes comands there.

where:
    -h|--help help (shows this message)
    -i path to private key file used for connection to target remotes
    -c|--command  command which should be executed on remotes
    --ihost target host that should be used as intermediate ssh connection. From there the connection to the target hosts is performed.
    -n|--number-split number of tmux splits per target
    TARGETS Targets where the commands should be executed."

SESSION_NAME="monitoring"

parse_arguments() {
	TARGET_HOSTS=()
    SSH_KEY=""
    COMMAND=""
    SPLIT_NUM="1"
	while [[ $# -gt 0 ]]; do
		key="$1"
		case $key in
			-i)
			SSH_KEY="-i $2"
			shift # past argument
			shift # past value
			;;
			-c|--command)
			COMMAND="$2"
			shift # past argument
			shift # past value
			;;
            --ihost)
			INTERMEDIATE_HOST="$2"
			shift # past argument
			shift # past value
			;;
            -n|--number-split)
			SPLIT_NUM="$2"
			shift # past argument
			shift # past value
			;;
            -h|--help)
			echo $USAGE
			exit 0
            ;;
			*)    # unknown option
			TARGET_HOSTS+=("$1") # save it in an array for later
			shift # past argument
			;;
		esac
	done
	set -- "${TARGET_HOSTS[@]}" # restore positional parameters
}

cmd() {
    if [ -z "$INTERMEDIATE_HOST" ]; then
        local cmd="ssh -o UserKnownHostsFile=/tmp/tmux-known-hosts -o StrictHostKeyChecking=no $SSH_KEY ubuntu@[TARGET] -t \"$COMMAND; bash -l\""
    else
        local cmd="ssh -o UserKnownHostsFile=/tmp/tmux-known-hosts -o StrictHostKeyChecking=no $INTERMEDIATE_HOST -t \"ssh -o UserKnownHostsFile=/tmp/tmux-known-hosts -o StrictHostKeyChecking=no $SSH_KEY ubuntu@[TARGET] -t \\\"$COMMAND; bash -l\\\"; bash -l\""
    fi
	echo "$cmd"
}

starttmux() {
    #Command to be executed in all tmux splits
    local cmd="$(cmd)"
    # Make local copy
    local hosts=("${TARGET_HOSTS[@]}")
    # Initial window creation and splitting
    tmux new-window "$(echo $cmd | sed "s/\[TARGET\]/${hosts[0]}/g")"
    for i in `seq 2 $SPLIT_NUM`; do
        tmux split-window -h "$(echo $cmd | sed "s/\[TARGET\]/${hosts[0]}/g")"
    done
    unset hosts[0];
	
    # All subsequent window splittings
    for i in "${hosts[@]}"; do
        tmux split-window -h  "$(echo $cmd | sed "s/\[TARGET\]/$i/g")"
        for i in `seq 2 $SPLIT_NUM`; do
            tmux split-window -v  "$(echo $cmd | sed "s/\[TARGET\]/$i/g")"
        done
        tmux select-layout tiled
		sleep 0.1
    done

    tmux select-pane -t 0
}

# The keyboard input is synchronized on all panes --> we dont need this but sometimes its a useful function
# (e.g. executing same command an a set of remote hosts)
#tmux set-window-option synchronize-panes on > /dev/null

parse_arguments "$@"
# At least one target must be defined
if [ ${#TARGET_HOSTS[@]} -lt 1 ]; then
    echo "No targets defined!"
    echo $USAGE
fi
# Start session if it is not already started
tmux has-session -t "$SESSION_NAME" &> /dev/null || tmux new-session -d -s "$SESSION_NAME"
# Do the cmd executions
starttmux
tmux select-window -t 0

