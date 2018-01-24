#!/bin/bash

test $# = 2 || { echo "Please provide a valid key file path and the name of the stack"; exit 1; }
STACK="$1"
KEY_FILE="$2"

######################################################################################################################################
#to be executed on client system
get_manager_ips()
{
	echo "Getting manager(s) IPs..."
	#by default first ip will be the leader
	MANAGERS_PUBLIC_IPS="$(openstack stack output show  clearwater swarm_manager_public_ips -c output_value -f value)"
	MANAGERS_PRIVATE_IPS="$(openstack stack output show  clearwater swarm_manager_private_ips -c output_value -f value)"

	#parse and export leader and other master ips
	length_public_ips=$(echo $MANAGERS_PUBLIC_IPS | jq length)
	length_private_ips=$(echo $MANAGERS_PRIVATE_IPS | jq length)
	if [ $length_private_ips -ne $length_public_ips ]; then 
		echo "Private IPs and Public IPs are not of same number. Check floating IP assignment."
		exit 1
	fi
	export SWARM_LEADER_PUBLIC="$(echo $MANAGERS_PUBLIC_IPS | jq -r '.[0]')"
	export LC_SWARM_LEADER_PRIVATE="$(echo $MANAGERS_PRIVATE_IPS | jq -r '.[0]')"
	#if there are more than one managers for swarm are created then get their ips so that they can join swarm as a manager
	if [ $length_public_ips > 1 ]; 
		then
		export REACHABLE_MANAGER_PUBLIC_IPS="$(echo $MANAGERS_PUBLIC_IPS | jq -r '.[1:]')"
		export LC_REACHABLE_MANAGER_PRIVATE_IPS="$(echo $MANAGERS_PRIVATE_IPS | jq -r '.[1:]')"
	fi
}
#to be executed on client system
get_node_private_ips()
{
	echo "Getting node(s) IPs..."
	#############
	ETCD_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater etcd_ips -c output_value -f value)"
	ELLIS_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater ellis_ips -c output_value -f value)"
	BONO_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater bono_ips -c output_value -f value)"
	SPROUT_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater sprout_ips -c output_value -f value)"
	HOMER_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater homer_ips -c output_value -f value)"
	HOMESTEAD_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater homestead_ips -c output_value -f value)"
	CASSANDRA_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater cassandra_ips -c output_value -f value)"
	ASTAIRE_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater astaire_ips -c output_value -f value)"
	HOMESTEAD_PROV_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater homesteadprov_ips -c output_value -f value)"
	CHRONOS_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater chronos_ips -c output_value -f value)"
	RALF_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater ralf_ips -c output_value -f value)"
	SIPP_STRESS_NODE_PRIVATE_IPS="$(openstack stack output show  clearwater sippstress_ips -c output_value -f value)"

	export LC_ETCD_PRIVATE_IPS=$(echo $ETCD_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_ELLIS_PRIVATE_IPS=$(echo $ELLIS_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_BONO_PRIVATE_IPS=$(echo $BONO_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_SPROUT_PRIVATE_IPS=$(echo $SPROUT_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_HOMER_PRIVATE_IPS=$(echo $HOMER_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_HOMESTEAD_PRIVATE_IPS=$(echo $HOMESTEAD_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_CASSANDRA_PRIVATE_IPS=$(echo $CASSANDRA_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_ASTAIRE_PRIVATE_IPS=$(echo $ASTAIRE_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_HOMESTEADPROV_PRIVATE_IPS=$(echo $HOMESTEAD_PROV_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_CHRONOS_PRIVATE_IPS=$(echo $CHRONOS_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_RALF_PRIVATE_IPS=$(echo $RALF_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
	export LC_SIPP_STRESS_PRIVATE_IPS=$(echo $SIPP_STRESS_NODE_PRIVATE_IPS | jq -r '.[]' | cut -d\s  -f1)
}

# to be executed on client system
get_zone()
{
	export ZONE=$(openstack stack output show  clearwater zone -c output_value -f value)
}

get_manager_ips
get_node_private_ips
get_zone

#TODO: to remove key file from the following command

scp -i $KEY_FILE -o StrictHostKeyChecking=no -r ./docker-compose.yaml ubuntu@$SWARM_LEADER_PUBLIC:~/

echo "Executing commands on swarm leader machine..."

ssh -i $KEY_FILE -o StrictHostKeyChecking=no -o SendEnv="LC_SWARM_LEADER_PRIVATE LC_REACHABLE_MANAGER_PRIVATE_IPS LC_ETCD_PRIVATE_IPS LC_ELLIS_PRIVATE_IPS LC_BONO_PRIVATE_IPS LC_SPROUT_PRIVATE_IPS LC_HOMER_PRIVATE_IPS LC_HOMESTEAD_PRIVATE_IPS LC_CASSANDRA_PRIVATE_IPS LC_ASTAIRE_PRIVATE_IPS LC_HOMESTEADPROV_PRIVATE_IPS LC_CHRONOS_PRIVATE_IPS LC_RALF_PRIVATE_IPS LC_SIPP_STRESS_PRIVATE_IPS" -A ubuntu@$SWARM_LEADER_PUBLIC 'bash -s' < swarm_create.sh






