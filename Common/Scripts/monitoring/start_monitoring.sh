#!/bin/bash
home=`dirname $(readlink -e $0)`

HOST_FILES=$(find "$home" -maxdepth 1 -type f -name '*.lst')
SESSION_NAME="monitoring"

tmux kill-session -t "$SESSION_NAME" &>> /dev/null

for i in $HOST_FILES; do
    # Parse target list files
    OLD_IFS=$IFS
	IFS=$'\n'
    TMP=( $(cat $i) )
    IFS=$OLD_IFS

    # Number of tmux window splits
    NUM_SPLITS=${TMP[0]}
    unset TMP[0]

	# Command to be executed on targets
    CMD="${TMP[1]}"
    unset TMP[1]

    # Intermediate SSH host
    INTER_HOST="${TMP[2]}"
    test -n "$INTER_HOST" && INTER_HOST="--ihost $INTER_HOST"
    unset TMP[2]

    # SSH key for intermediate host
    SSH_KEY="${TMP[3]}"
    test -n "$SSH_KEY" && SSH_KEY="-i $SSH_KEY"
    unset TMP[3]
	
	# Target hosts
    HOSTS=${TMP[@]}
    
    "$home/tmux_exec_cmd.sh" $SSH_KEY -c "$CMD" $INTER_HOST -n "$NUM_SPLITS" ${HOSTS[@]}
done

tmux a -t "$SESSION_NAME"
