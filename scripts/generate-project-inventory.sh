#!/bin/bash
set -e

usage="$(basename $0) -p|--prefix [--hypervisors] -- generate ansible inventory file in ini format.

where:
    -p|--prefix         Prefix to indentify testbed VMs and networks. Should be the same as the one used at the heat stack creation. Required option.
    --hypervisors       Generate inventory entries for hypervisor nodes. Note that you must have admin rights in OpenStack. 
                        Otherwise enabling this option will cause the script to fail.
    --vms               Output a [vms:children] group containing all generated hosts
    -h|--help           Print this help message."

function warn() { >&2 echo $@; }

PREFIX=""
GENERATE_HYPERVISOR_ENTRIES=false
GENERATE_VMS_GROUP=false
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -p|--prefix) PREFIX="$2"; shift 2 ;;
        --hypervisors) GENERATE_HYPERVISOR_ENTRIES=true; shift ;;
        --vms) GENERATE_VMS_GROUP=true; shift ;;
        -h|--help) warn $usage; exit 0 ;;
        *) warn "Bad parametrization."; warn $usage; exit -1 ;;
    esac
done

function output_group() {
    NAME="$1"
    echo -e "\n[$NAME]"
    shift
    if [ "$NAME" = "hypervisors" ]; then
        local HOST_TYPE="hypervisor"
    else
        local HOST_TYPE="vm"
    fi

    sorted_hosts=$(echo $@ | tr  [:space:] '\n' | sort -V)
    for host in $sorted_hosts; do
        local PUBLIC_IP="${PUBLIC_IPS[$host]}"
        local PRIVATE_IP="${PRIVATE_IPS[$host]}"
		local ZONE="${ZONES[$host]}"
        local HYPERVISOR="${HYPERVISOR_LIST[$host]}"
        local LIBVIRT_ID="${LIBVIRT_IDS[$host]}"
        test -z "$PUBLIC_IP" && { warn "Warning: No public IP found for host $host. Not adding to group $NAME"; continue; }
        output="$host ansible_host=$PUBLIC_IP"
        test -n "$PRIVATE_IP" && { output="$output private_ip=$PRIVATE_IP"; }
		test -n "$ZONE" && { output="$output zone=$ZONE"; }
        test -n "$HYPERVISOR" && { output="$output hypervisor=$HYPERVISOR"; }
        test -n "$LIBVIRT_ID" && { output="$output libvirt_id=$LIBVIRT_ID"; }
        test -n "$HOST_TYPE" && { output="$output host_type=$HOST_TYPE"; }
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
declare -A HYPERVISOR_LIST
declare -A LIBVIRT_IDS
HYPERVISORS=""
ALL_VMS=""

if $GENERATE_HYPERVISOR_ENTRIES ; then
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
fi

HOST_INFO=$(openstack host list -f json)
while read -r hy_zone; do
	hz=($hy_zone)
	ZONES["${hz[0]}"]="${hz[1]}"
done < <(echo "$HOST_INFO" | jq -rM '.[] | select(."Zone" != "internal") | ."Host Name" + " " + ."Zone"')

if [ -n "$PREFIX" ]; then
    warn "Querying list of VMs named '$PREFIX*'..."
    VM_IDS=$(openstack server list --name "^$PREFIX.*" -f json -c ID | jq -rM '.[].ID')
    for ID in $VM_IDS; do
        warn "Querying info of VM '$ID'..."
        INFO=$(openstack server show "$ID" -f json -c name -c addresses -c properties -c OS-EXT-AZ:availability_zone -c OS-EXT-SRV-ATTR:host -c OS-EXT-SRV-ATTR:instance_name)

        #Get VM name
        NAME=$(echo "$INFO" | jq -rM .name)
        # Get availability zone of VM
        ZONE=$(echo "$INFO" | jq -rM '."OS-EXT-AZ:availability_zone"')
        # Get hypervisor of VM
        HYPERVISOR=$(echo "$INFO" | jq -rM '."OS-EXT-SRV-ATTR:host"')
        # Get Libvirt ID of VM
        LIBVIRT_ID=$(echo "$INFO" | jq -rM '."OS-EXT-SRV-ATTR:instance_name"')
        
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
        HYPERVISOR_LIST[$NAME]=$HYPERVISOR
        LIBVIRT_IDS[$NAME]=$LIBVIRT_ID
    done
fi

# Create sections for VM_GROUPS
for group in ${!VM_GROUPS[@]}; do
    output_group $group ${VM_GROUPS[$group]}
done

if $GENERATE_VMS_GROUP; then
    output_meta_group "vms:children" ${!VM_GROUPS[@]}
fi
if $GENERATE_HYPERVISOR_ENTRIES; then
    output_group "hypervisors" $HYPERVISORS
fi
