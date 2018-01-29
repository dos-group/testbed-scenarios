#!/bin/bash
set -e

function warn() { >&2 echo $@; }

test $# = 2 || { warn "Need 2 parameters: prefix to identify VMs to use + public IP address prefix"; exit 1; }
VM_PREFIX="$1"
IP_PREFIX="$2"

function output_group() {
    NAME="$1"
    echo -e "\n[$NAME]"
    shift
    for host in $@; do
        IP="${HOST_IPS[$host]}"
        if [ -z "$IP" ]; then
            warn "Warning: No IP found for host $host. Not adding to group $NAME"
        else
            echo "$host ansible_host=$IP"
        fi
    done
}

function output_meta_group() {
    echo -e "\n[$1]"
    shift
    for child in $@; do
        echo "$child"
    done
}

declare -A VM_GROUPS
declare -A HOST_IPS
HYPERVISORS=""
ALL_VMS=""

VM_IDS=$(openstack server list --name "^$VM_PREFIX.*" -f json -c ID | jq -rM '.[].ID')
for ID in $VM_IDS; do
    INFO=$(openstack server show "$ID" -f json -c name -c OS-EXT-SRV-ATTR:hypervisor_hostname -c addresses -c properties)
    HYPERVISOR=$(echo "$INFO" | jq -rM '."OS-EXT-SRV-ATTR:hypervisor_hostname"')
    NAME=$(echo "$INFO" | jq -rM .name)

    # Easiest hack to parse the stupid OpenStack metadata properties format: replace comma with semicolon and eval in a subshell
    # Example: stack='video-server-5', xxx='yyy'
    META=$(echo "$INFO" | jq -rM .properties)
    VM_GROUP=$(eval $(echo "$META" | sed "s/,/;/g"); echo "$group")
    test -z "$VM_GROUP" && {
        warn "No 'group' metadata found for VM '$NAME'. Using 'default' group."
        VM_GROUP="default"
    }

    # Count the number of '=' characters. We only support parsing for a single network.
    # Example: private-net=10.0.0.11, 10.0.42.65
    NETWORKS=$(echo "$INFO" | jq -rM .addresses)
    NUM_NETWORKS=$(echo "$NETWORKS" | awk -F= '{print NF-1}')
    test "$NUM_NETWORKS" -eq 1 || { warn "The VM '$NAME' has $NUM_NETWORKS networks. Can only parse 1 network, skipping VM."; continue; }
    IPS=$(echo "$NETWORKS" | cut -d= -f 2 | sed 's/,/ /g')
    FOUND_IP=""
    for i in $IPS; do
        if [[ "$i" = "$IP_PREFIX"* ]]; then
            if [ -z "$FOUND_IP" ]; then
                FOUND_IP="$i"
            else
                warn "VM '$NAME' has multiple IPs with prefix $IP_PREFIX: $FOUND_IP $i. Using $FOUND_IP."
                break
            fi
        fi
    done
    test -z "$FOUND_IP" && { warn "No IP with prefix $IP_PREFIX found for VM '$NAME', skipping VM. Found IPs:" $IPS; continue; }

    # Do these assignments only after all above checks have passed
    HYPERVISORS="$HYPERVISORS $HYPERVISOR"
    VM_GROUPS[$VM_GROUP]="${VM_GROUPS[$VM_GROUP]} $NAME"
    ALL_VMS="$ALL_VMS $NAME"
    HOST_IPS[$NAME]="$FOUND_IP"
done

# Create sections for VM_GROUPS
for group in ${!VM_GROUPS[@]}; do
    output_group $group ${VM_GROUPS[$group]}
done
output_meta_group vms ${!VM_GROUPS[@]}

# Create sections for hypervisors
HYPERVISORS=$(echo "$HYPERVISORS" | tr ' ' '\n' | sort | uniq | tr '\n' ' ')
output_meta_group hypervisors $HYPERVISORS
