#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

LOAD_NODES=1
declare -A ZONE_NODE_NUMBER
declare -A ZONE_NODES

usage(){
	echo "This script expects a set of argument-parameter-pairs, defining the assignment of hypervisor nodes to availability zones."
	echo "Usage: $0 [-r|--ratio] --<availability_zone_name> <parameter> [--<availability_zone_name> <parameter>] ..."
	echo '--<availability_zone_name>	Definition of an availability zone, that will be created not already there'
	echo '<parameter> 			Value that defines the amount of hypervisors, that should be assigned to the respective availability zone. Can be either a fixed amount or a ratio value (see -r|--ratio).'
	echo '-r|--ratio 			Instead of defining a fixed amount of hypervisors to be assigned to an availabilityzone, it is possible to define ratios instead. Sum of all ratios must sum up to 1.'
	exit 1
}

# Check if array contains an element
contains_element () { 
    local seeking=$1; shift
    local in=1
    for element; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

# Check if node ratios sum up to 1
check_zone_ratios() {
	local ratio_sum="0"
	for zone in ${!ZONE_NODE_NUMBER[@]}; do
		ratio_sum=$(echo "$ratio_sum + ${ZONE_NODE_NUMBER[$zone]}" | bc)
	done
	if [[ $(echo "$ratio_sum!=1" | bc -l) -eq 1 ]]; then
		echo "Invalid zone ratio definitions. Must sum up to 1."
		exit 1
	fi
}

# Fix node numbers if there are more assigned nodes to the availability zones than actual nodes are present in the system
# First the availability zone with the highest number of nodes is reduced. Will round robin over all nodes until the
# overflow is fixed. Will prevent node number to fall under 1.
fix_zone_node_numbers() {
	local ratio=""
	local sorted_zones=""
	local value_to_fix="$1"
	local operator="$2"
	for zone in ${!ZONE_NODE_NUMBER[@]}; do
		ratio=$(echo "${ZONE_NODE_NUMBER[$zone]} * 1000000" | bc | awk '{printf "%.0f", $0}')
		sorted_zones=$(printf '%s%s  -  %s\\n' "$sorted_zones" "$zone" "$ratio")
	done 
	sorted_zones=$(echo -e "$sorted_zones" | sort -nr -k3 | cut -f 1 -d ' ' | xargs printf '%s\\n')
	sorted_zones=($(echo -e "$sorted_zones"))

	local index=0
	local iteration_counter=0
	while [[ $value_to_fix -ne 0 ]]; do
		if ! [[ ${ZONE_NODE_NUMBER[${sorted_zones[$index]}]} -le 1 && $operator = "-" ]]; then
			ZONE_NODE_NUMBER[${sorted_zones[$index]}]="$(( ${ZONE_NODE_NUMBER[${sorted_zones[$index]}]} $operator 1 ))"
			value_to_fix=$(( $value_to_fix - 1))
		fi
		iteration_counter=$(( $iteration_counter + 1 ))
		index=$(( $iteration_counter % ${#ZONE_NODE_NUMBER[@]} ))
	done
}

# Fix node numbers if there are nodes which are not assigned to availability zones. So the assignment does not considered all
# nodes and thus, they will be distributed over all availability zones. First, it iterated over all nodes and adds nodes to the
# zones where the node number is 0. After that, it starts to assign the remaining nodes to the zones starting with the ones having
# the highst ratios. It goes round robin in descending order.
fix_underflow() {
	local ratio=""
	local sorted_zones=""
	local value_to_fix="$1"

	for zone in ${!ZONE_NODE_NUMBER[@]}; do
		if [[ $value_to_fix -eq 0 ]]; then
			break
		fi
		if [[ ${ZONE_NODE_NUMBER[$zone]} -eq 0 ]]; then
			ZONE_NODE_NUMBER[$zone]="1"
			value_to_fix=$(( $value_to_fix - 1))
		fi
	done

	if [[ $value_to_fix -ne 0 ]]; then
		fix_zone_node_numbers $value_to_fix "+"
	fi
} 

# Filling the zone map with concrete nodes (node names)
fill_zone_nodes() {
	local zone="$1"
	local global_index="$2"
	local index=0

	while [[ $index -ne ${ZONE_NODE_NUMBER[$zone]} ]];  do
		ZONE_NODES[$zone]="${ZONE_NODES[$zone]} ${HOSTS[$global_index]}"
		index=$(( $index + 1 ))	
		global_index=$(( $global_index + 1 ))
	done
}

# Applies the previous created availability zone configuration on openstack
# Creates zones if missing. Checks hypervisors. Moves them to assigned availability zone.
apply_availability_zones_on_openstack() {
	local json_cfg="$1"

	# Get current host information
	HOST_ZONE_INFO=$(openstack host list -f json)
	echo "Checking availability zones and hypervisor nodes..."
	ZONES=($(echo "$json_cfg" | jq -rM 'keys[] as $k | "\($k)"' | tr '\n' ' '))
	CURRENT_ZONES=($(openstack aggregate list -f json | jq -rM '.[]."Availability Zone"' | tr '\n' ' '))
	for ZONE in ${ZONES[@]}; do
		# Create missing availability zones
		contains_element "$ZONE" "${CURRENT_ZONES[@]}" || {
			echo "Creating $ZONE..."
			openstack aggregate create --zone $ZONE $ZONE &> /dev/null
		}
		for HOST in $(echo "$json_cfg" | jq -rM ".$ZONE | .[]"); do
			HOST_ZONE=$(echo "$HOST_ZONE_INFO" | jq -rM ".[] | select(.\"Host Name\" == \"$HOST\") | .\"Zone\"")
			# Put hosts into assigned availability zone
			if [ "$HOST_ZONE" != "$ZONE" ]; then
				echo "Moving host $HOST from zone $HOST_ZONE to zone $ZONE..."
				openstack aggregate remove host $HOST_ZONE $HOST &> /dev/null
				openstack aggregate add host $ZONE $HOST &> /dev/null
			fi 
		done
	done
}

# Argument parsing
NUM_REG='^[0-9]+([.][0-9]+)?$'
IS_RATIO=0
while [[ $# -gt 0 ]]; do
  case "$1" in 
    -r|--ratio)
       	IS_RATIO=1
       	shift ;;
	-h|--help)
		usage
		;;
    --*)
		if ! [[ $yournumber =~ $re ]] ; then
   			echo "$2 is not a valid number" &&  exit 1
		fi
		zone=$1
		ZONE_NODE_NUMBER[${zone:2}]=$2
		shift 2 ;;
	*)
		usage
		;;	
  esac
done

# Get current host information
echo "Pulling host information..."
HOST_ZONE_INFO=$(openstack host list -f json)
HOSTS=($(echo "$HOST_ZONE_INFO" | jq -rM '.[] | select(."Zone" != "internal") | ."Host Name"'))
if [ ${#HOSTS[@]} -lt ${#ZONES[@]} ]; then
	echo "Not enought hypervisors available. Need at least $(( ${#ZONES[@]} + 1 ))"
	exit 1
fi

if [[ $IS_RATIO -eq 1 ]]; then
	# Check whether the zone ratio deficitions sum up to 1
	check_zone_ratios
	# Calculate node numbers bases on ratio definition 
	sum=0
	for zone in ${!ZONE_NODE_NUMBER[@]}; do
		RATIO=${ZONE_NODE_NUMBER[$zone]}
		ZONE_NODE_NUMBER[$zone]=$(echo "$RATIO * ${#HOSTS[@]}" | bc |  awk '{printf "%.0f", $0}')
		sum=$(( $sum + ${ZONE_NODE_NUMBER[$zone]} ))
	done

	# Check if the calculated number are exact the amount of available nodes (could not be the case due to rounding)
	OVER_UNDER_FLOW=$(( $SUM - ${#HOSTS[@]} ))
	if [[ $OVER_UNDER_FLOW -lt 0 ]]; then # Underflow scenario
		fix_underflow $(($OVER_UNDER_FLOW * -1 ))
	elif [[ $OVER_UNDER_FLOW -gt 0 ]]; then # Overflow scenario
		fix_zone_node_numbers $OVER_UNDER_FLOW "-"
	fi
elif [[ $RATIO -eq 0 ]]; then
	sum=0
	for node_number in ${ZONE_NODE_NUMBER[@]}; do
		if [[ $node_number -ne $node_number ]]; then
			echo "$node_number is not a valid integer" && exit
		fi
		sum=$(( $sum + $node_number ))
	done
	if [[ $sum -gt ${#HOSTS[@]} ]]; then
		echo "There are more host that should be assigned to availability zones ($sum) than actually available $(${#HOSTS[@]})." && exti 1
	fi
fi

echo "Assigning nodes to availability zones..."
INDEX=0
for zone in ${!ZONE_NODE_NUMBER[@]}; do
	fill_zone_nodes $zone $INDEX
	INDEX=$(( $INDEX + ${ZONE_NODE_NUMBER[$zone]} ))
	echo "$zone: ${ZONE_NODES[$zone]}"
done

JSON="{"
for zone in ${!ZONE_NODES[@]}; do
	JSON="$JSON \"$zone\":["
	for node in ${ZONE_NODES[$zone]}; do
		JSON="$JSON \"$node\","
	done
	JSON=${JSON::-1}
	JSON="$JSON ],"
done
JSON=${JSON::-1}
JSON="$JSON }"

echo "Applying configuration..."
apply_availability_zones_on_openstack "$JSON"



