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
		ZONE="${ZONES[$host]}"
        test -z "$PUBLIC_IP" && { warn "Warning: No public IP found for host $host. Not adding to group $NAME"; continue; }
        output="$host ansible_host=$PUBLIC_IP"
        test -n "$PRIVATE_IP" && { output="$output private_ip=$PRIVATE_IP"; }
		test -n "$ZONE" && { output="$output zone=$ZONE"; }
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
declare -A ZONES
HYPERVISORS=""
ALL_VMS=""

warn "Querying hypervisor information..."
HYPERVISOR_INFO=$(openstack hypervisor list -f json)
for ID in $(echo "$HYPERVISOR_INFO" | jq -rM '.[]."ID"' | tr '\n' ' '); do
	warn "Querying info of hypervisor '$ID'..."
	INFO=$(openstack hypervisor show $ID -f json -c hypervisor_hostname -c service_host)
	HYPERVISOR=$(echo "$INFO" | jq -rM '.service_host')
	HYPERVISOR_HOSTNAME=$(echo "$INFO" | jq -rM '.hypervisor_hostname')
	PUBLIC_IPS["$HYPERVISOR"]=$HYPERVISOR_HOSTNAME
	HYPERVISORS="$HYPERVISORS $HYPERVISOR"
done

HOST_INFO=$(openstack host list -f json)
while read -r hy_zone; do
	hz=($hy_zone)
	ZONES["${hz[0]}"]="${hz[1]}"
done < <(echo "$HOST_INFO" | jq -rM '.[] | select(."Zone" != "internal") | ."Host Name" + " " + ."Zone"')

warn "Querying list of VMs named '$PREFIX*'..."
VM_IDS=$(openstack server list --name "^$PREFIX.*" -f json -c ID | jq -rM '.[].ID')
for ID in $VM_IDS; do
    warn "Querying info of VM '$ID'..."
    INFO=$(openstack server show "$ID" -f json -c name -c addresses -c properties -c OS-EXT-AZ:availability_zone)

	#Get VM name
    NAME=$(echo "$INFO" | jq -rM .name)
	# Get availability zone of VM
	ZONE=$(echo "$INFO" | jq -rM '."OS-EXT-AZ:availability_zone"')

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
    VM_GROUPS[$VM_GROUP]="${VM_GROUPS[$VM_GROUP]} $NAME"
    ALL_VMS="$ALL_VMS $NAME"
    PUBLIC_IPS[$NAME]="$PUBLIC_IP"
    PRIVATE_IPS[$NAME]="$PRIVATE_IP"
	ZONES[$NAME]=$ZONE
done

# Create sections for VM_GROUPS
for group in ${!VM_GROUPS[@]}; do
    output_group $group ${VM_GROUPS[$group]}
done
output_meta_group vms:children ${!VM_GROUPS[@]}

output_group hypervisors $HYPERVISORS

