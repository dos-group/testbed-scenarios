#!/bin/bash
home=`dirname $(readlink -e $0)`

function warn() { >&2 echo $@; }

RC_FILE="/home/alex/workspace/alexander_project-openrc.sh"
# Make argument
PREFIX="vod"
NUM_RETRIES=3
LOAD_SCRIPT="$home/set-rtmp-streams.yml"
LOAD=80

ANSIBLE_PLAYBOOK="$home/../Ansible/playbook.yml"
NUM_RETRY_ANSIBLE=$NUM_RETRIES
NUM_RETRY_VM_REBOOT=$NUM_RETRIES
SLEEP_BETWEEN_RETRIES=30


# Disable load
ansible-playbook -e NUM_RTMP_STREAMS=0 $LOAD_SCRIPT

# Source for OpenStack CLI access
source $RC_FILE
# Restart all VMs
VM_IDS=$(openstack server list --name "^$PREFIX.*" -f json -c ID | jq -rM '.[].ID')
for ID in $VM_IDS; do
    warn "Hard rebooting VM '$ID'..."
    # Retry several times for each VM
    while [ $NUM_RETRY_VM_REBOOT -gt 0 ]; do
        RESULT=$(openstack server reboot --hard --wait "$ID")
        if [ $? -ne 0 ]; then
            $NUM_RETRY_ANSIBLE=$((NUM_RETRY_ANSIBLE - 1))
            warn "Reboot of VM '$ID' failed. Output: $RESULT. Waiting for $SLEEP_BETWEEN_RETRIES seconds until retry. " + \
                 "Remaining number of retries: $NUM_RETRY_ANSIBLE." 
            sleep $SLEEP_BETWEEN_RETRIES
        else
            break # Reboot was successful
        fi
    done
    # All retries failes. Exit script with error.
    if [ $NUM_RETRY_VM_REBOOT -le 0 ]; then
        warn "Failed to reboot VM '$ID' after $NUM_RETRY_ANSIBLE retries. Exiting script..."
        exit 1
    else
        NUM_RETRY_VM_REBOOT=$NUM_RETRIES
    fi
done

# Setup VMs
while [ $NUM_RETRY_ANSIBLE -gt 0 ]; do
    $ANSIBLE_PLAYBOOK
    if [ $? -ne 0 ]; then
        $NUM_RETRY_ANSIBLE=$((NUM_RETRY_ANSIBLE - 1))
        warn "Ansible script $ANSIBLE_PLAYBOOK to setup testbed failed. Waiting for $SLEEP_BETWEEN_RETRIES seconds until retry. " + \
             "Remaining number of retries: $NUM_RETRY_ANSIBLE." 
        sleep $SLEEP_BETWEEN_RETRIES
    else
        break        
    fi
done

# Set load
ansible-playbook -e NUM_RTMP_STREAMS=$LOAD $LOAD_SCRIPT








