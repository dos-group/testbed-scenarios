#!/bin/bash
home=`dirname $(readlink -e $0)`

test $# = 2 || { echo "Parameters: stack name + private key file"; exit 1; }
export STACK="$1"
KEY_FILE="$2"

function query_array_0() { openstack stack output show "$STACK" "$1" -f json | jq -rM '.output_value[0]'; }
function query_array_remainder() { openstack stack output show "$STACK" "$1" -f json | jq -rM '.output_value[1:][]'; }
function query_array_all() { openstack stack output show "$STACK" "$1" -f json | jq -rM '.output_value[]'; }

function query_compare_lengths() {
	len1=$(openstack stack output show "$STACK" "$1" -f json | jq length)
	len2=$(openstack stack output show "$STACK" "$2" -f json | jq length)
	test $len1 = $len2 || { echo "The Heat outputs '$1' and '$2' do not have the same lengths ($len1 != $len2)!"; return 1; }
}

######################################################################################################################################
get_manager_ips()
{
	query_compare_lengths swarm_manager_public_ips swarm_manager_private_ips || exit 1
	SWARM_LEADER_PUBLIC=$(query_array_0 swarm_manager_public_ips)
	export LC_INITIAL_MANAGER=$(query_array_0 swarm_manager_private_ips)
	export LC_OTHER_MANAGERS="$(query_array_remainder swarm_manager_private_ips)"
}

get_node_private_ips()
{
	echo "Getting node(s) IPs..."
	#############
	ETCD_NODE_PRIVATE_IPS="$(query_array_all   etcd_ips)"
	ELLIS_NODE_PRIVATE_IPS="$(query_array_all  ellis_ips)"
	BONO_NODE_PRIVATE_IPS="$(query_array_all   bono_ips)"
	SPROUT_NODE_PRIVATE_IPS="$(query_array_all sprout_ips)"
	HOMER_NODE_PRIVATE_IPS="$(query_array_all  homer_ips)"
	HOMESTEAD_NODE_PRIVATE_IPS="$(query_array_all  homestead_ips)"
	CASSANDRA_NODE_PRIVATE_IPS="$(query_array_all  cassandra_ips)"
	ASTAIRE_NODE_PRIVATE_IPS="$(query_array_all   astaire_ips)"
	HOMESTEAD_PROV_NODE_PRIVATE_IPS="$(query_array_all  homesteadprov_ips)"
	CHRONOS_NODE_PRIVATE_IPS="$(query_array_all   chronos_ips)"
	RALF_NODE_PRIVATE_IPS="$(query_array_all   ralf_ips)"
	SIPP_STRESS_NODE_PRIVATE_IPS="$(query_array_all  sippstress_ips)"

	export LC_WORKERS="$ETCD_PRIVATE_IPS $ELLIS_PRIVATE_IPS $BONO_PRIVATE_IPS $SPROUT_PRIVATE_IPS $HOMER_PRIVATE_IPS $HOMESTEAD_PRIVATE_IPS $CASSANDRA_PRIVATE_IPS $ASTAIRE_PRIVATE_IPS $HOMESTEADPROV_PRIVATE_IPS $CHRONOS_PRIVATE_IPS $RALF_PRIVATE_IPS $SIPP_STRESS_PRIVATE_IPS"
}

# to be executed on client system
get_zone()
{
	export ZONE=$(openstack stack output show  $STACK zone -c output_value -f value)
}

get_manager_ips
get_node_private_ips
get_zone

scp -i $KEY_FILE -o StrictHostKeyChecking=no -r ./docker-compose.yaml ubuntu@$SWARM_LEADER_PUBLIC:~/

echo "Executing commands on swarm leader machine..."

export LC_STACK_NAME="clearwater-stack"
ssh -i $KEY_FILE -o StrictHostKeyChecking=no \
	-o SendEnv="LC_INITIAL_MANAGER LC_OTHER_MANAGERS LC_WORKERS LC_STACK_NAME" \
	-A ubuntu@$SWARM_LEADER_PUBLIC 'bash -s' < "$home/../../Common/docker-swarm-initialize-remote.sh"
