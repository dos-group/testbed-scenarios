#!/bin/bash
set -e

function warn() { >&2 echo $@; }

test $# = 1 || { warn "Need 1 parameter: prefix to identify VMs and networks to use"; exit 1; }
PREFIX="$1"

function output_group() {
    NAME="$1"
    echo -e "\n[$NAME]"
    shift
    for host in $@; do
        PUBLIC_IP="${PUBLIC_IPS[$host]}"
        PRIVATE_IP="${PRIVATE_IPS[$host]}"
        test -z "$PUBLIC_IP" && { warn "Warning: No public IP found for host $host. Not adding to group $NAME"; continue; }
        output="$host ansible_host=$PUBLIC_IP"
        test -n "$PRIVATE_IP" && { output="$output private_ip=$PRIVATE_IP"; }
        echo "$output"
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
declare -A PUBLIC_IPS
declare -A PRIVATE_IPS
HYPERVISORS=""
ALL_VMS=""

warn "Querying list of VMs named '$PREFIX*'..."
VM_IDS=$(openstack server list --name "^$PREFIX.*" -f json -c ID | jq -rM '.[].ID')
for ID in $VM_IDS; do
    warn "Querying info of VM '$ID'..."
    INFO=$(openstack server show "$ID" -f json -c name -c OS-EXT-SRV-ATTR:hypervisor_hostname -c addresses -c properties)



	# Only  if VM runs on hypervisor, it is added to the inventory... 
	# TODO: Add (primary) availability zone (first one in the list) as variable?


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

    # Example output: "private-net=10.0.0.11, 10.0.42.65; other-net=192.168.0.11"
    # Most likely, the first IP address is the private one, the second is public
    NETWORKS=$(echo "$INFO" | jq -rM .addresses)
    PRIVATE_IP=""
    PUBLIC_IP=""
    MYIFS="${IFS},=" # Treat '=' and ',' like white space for simpler processing
    while IFS="$MYIFS" read -d ';' net_name ip1 ip2 remainder; do
        if [[ "$net_name" = $PREFIX* ]]; then
            PRIVATE_IP="$ip1"
            PUBLIC_IP="$ip2"
            break
        fi
    done <<< "${NETWORKS};" # Append a semicolon to enable 'read' to process the last (and possibly only) entry
    test -z "$PUBLIC_IP" && { echo "Private & public IPs not found for VM '$NAME' in network named '$PREFIX*', skipping VM. Network info: $NETWORKS"; continue; }

    # Do these assignments only after all above checks have passed
    HYPERVISORS="$HYPERVISORS $HYPERVISOR"
    VM_GROUPS[$VM_GROUP]="${VM_GROUPS[$VM_GROUP]} $NAME"
    ALL_VMS="$ALL_VMS $NAME"
    PUBLIC_IPS[$NAME]="$PUBLIC_IP"
    PRIVATE_IPS[$NAME]="$PRIVATE_IP"
done

# Create sections for VM_GROUPS
for group in ${!VM_GROUPS[@]}; do
    output_group $group ${VM_GROUPS[$group]}
done
output_meta_group vms:children ${!VM_GROUPS[@]}

# Create a section for hypervisors
HYPERVISORS=$(echo "$HYPERVISORS" | tr ' ' '\n' | sort | uniq | tr '\n' ' ')
HYPERVISORS_SHORT=""
for hv in $HYPERVISORS; do
    # TODO this might be different for other hostnames. Here, we strip all DNS-name parts except for the first one.
    HV_SHORT=$(echo "$hv" | cut -f1 -d".")
    PUBLIC_IPS[$HV_SHORT]="$hv"
    HYPERVISORS_SHORT="$HYPERVISORS_SHORT $HV_SHORT"
done
output_group hypervisors $HYPERVISORS_SHORT

