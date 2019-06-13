#!/bin/bash
home=`dirname $(readlink -e $0)`
cd $home

usage="$(basename $0) -p|--prefix [-r|--rc_file] [-n|--num_retries] [-s|--sleep] [-h|--help] -- reset VoD testbed

where:
    -p|--prefix         Prefix to indentify testbed VMs. Should be the same as the one used at the heat stack creation. Required option.
    -r|--rc_file        Path to RC file which should be sources in order to access openstack cli.
    -n|--num_retries    Number of retries for each operation until it is considered to have failed (default is 3).
    -s|--sleep          Sleep time between retries in seconds (default is 10 seconds).
    -h|--help           Print this help message."

function warn() { >&2 echo $@; }
function print() { >&1 echo $@; }

ANSIBLE_DIR="../Ansible"
LOAD_SCRIPT="./set-rtmp-streams.yml"
ANSIBLE_PLAYBOOK="./playbook.yml"

RC_FILE=""
PREFIX=""
NUM_RETRIES=3
SLEEP_BETWEEN_RETRIES=10
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--rc_file)
        RC_FILE="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--prefix)
        PREFIX="$2"
        shift 
        shift 
        ;;
        -n|--num_retries)
        NUM_RETRIES="$2"
        shift
        shift
        ;;
        -s|--sleep)
        SLEEP_BETWEEN_RETRIES="$2"
        shift 
        ;;
        -h|--help)
        echo $usage
        exit 0
        ;;
        *)    # unknown option
        echo "Bad parametrization"
        echo $usage
        exit -1
        ;;
    esac
done

if [ -z "$PREFIX" ]; then
    warn "Missing required option -p|--prefix. Should be the same as was used on heat stack creation. Prefix, of every instance of the testbed."
    echo "$usage"
    exit 1
fi
if [ -z "$RC_FILE" ]; then
    print "No RC file defined. Checking of OpenStack CLI..."
    openstack server list > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        warn "OpenStack CLI not available. Authenticate by providing an RC file or source it before running this script."
        exit 1
    fi
fi

function retry_execution() {
    local LOCAL_NUM_RETRIES=$NUM_RETRIES
    while [ $LOCAL_NUM_RETRIES -gt 0 ]; do
        $@
        if [ $? -ne 0 ]; then
            local LOCAL_NUM_RETRIES=$((LOCAL_NUM_RETRIES - 1))
            echo "Execution of command $@ failed. Output: $RESULT. Waiting for $SLEEP_BETWEEN_RETRIES seconds until retry. " \
                  "Remaining number of retries: $LOCAL_NUM_RETRIES." >&2
            if [ $LOCAL_NUM_RETRIES -gt 0 ]; then
                sleep $SLEEP_BETWEEN_RETRIES
            fi
        else
            break # Command execution was successful
        fi
    done
    # All retries failed. Exit function with error.
    if [ $LOCAL_NUM_RETRIES -le 0 ]; then
        echo "Execution of command $@ failed after $NUM_RETRIES retries. Exiting with error." >&2
        return 1
    fi
    return 0
}

# Disable load (can fail, does not matter that much)
ansible-playbook -e NUM_RTMP_STREAMS=0 "$LOAD_SCRIPT"

# Source for OpenStack CLI access
if [ ! -z "$RC_FILE" ]; then 
    if [ ! -f "$RC_FILE" ]; then
        warn "RC file $RC_FILE does not exist. Cannot execute script."
        exit 1
    fi
    source $RC_FILE
fi

# Restart all VMs
VM_IDS=$(openstack server list --name "^$PREFIX.*" -f json -c ID | jq -rM '.[].ID')
if [ $? -ne 0 ]; then
    print "Failed to get OpenStack VM IDs. Exiting with error. $VM_IDS"
    exit 1
fi
for ID in $VM_IDS; do
    print "Hard rebooting VM '$ID'..."
    # Retry several times for each VM
    retry_execution "openstack server reboot --hard --wait $ID"
    if [ $? -ne 0 ]; then
        print "Failed to reboot VM '$ID'. Exiting with error."
        exit 1
    fi
done

# Setup VMs
cd "$home/$ANSIBLE_DIR"
print "Setting up VMs with ansible script $ANSIBLE_PLAYBOOK..."
retry_execution "ansible-playbook $ANSIBLE_PLAYBOOK"
# All retries failes. Exit script with error.
if [ $? -ne 0 ]; then
    print "Failed to setup VMs with ansible script $ANSIBLE_PLAYBOOK. Exiting with error."
    exit 1
fi

