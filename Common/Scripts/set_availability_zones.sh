#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

usage(){
	echo $(printf "Expects either a json configuration string or a path to a file containing a json configuration string. See $home/zones.json.template Usage: $0 [-f|--file <path> | <json config string>]")
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

#Argument parsing
POSITIONAL=()
JSON_CFG=""
JSON_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in 
    -f|--file)
       	JSON_FILE="$2"
       	shift 2 ;;
    *)
		POSITIONAL+=("$1")
		shift ;;
  esac
done
set -- "${POSITIONAL[@]}"

#Argument checking
if [ "${#POSITIONAL[@]}" -eq 1 ] && [ -z "$JSON_FILE" ]; then
	JSON_CFG="${POSITIONAL[0]}"
elif [ -n "$JSON_FILE" ] && [ "${#POSITIONAL[@]}" -eq 0 ]; then
	JSON_CFG=$(cat "$JSON_FILE")
else
	usage
fi

# Get current host information
HOST_ZONE_INFO=$(openstack host list -f json)

echo "Checking availability zones and hypervisor nodes..."
ZONES=($(echo "$JSON_CFG" | jq -rM 'keys[] as $k | "\($k)"' | tr '\n' ' '))
CURRENT_ZONES=($(openstack aggregate list -f json | jq -rM '.[]."Availability Zone"' | tr '\n' ' '))
for ZONE in ${ZONES[@]}; do
	# Create missing availability zones
	contains_element "$ZONE" "${CURRENT_ZONES[@]}" || {
		echo "Creating $ZONE..."
		openstack aggregate create --zone $ZONE $ZONE &> /dev/null
	}
	for HOST in $(echo "$JSON_CFG" | jq -rM ".$ZONE | .[]"); do
		HOST_ZONE=$(echo "$HOST_ZONE_INFO" | jq -rM ".[] | select(.\"Host Name\" == \"$HOST\") | .\"Zone\"")
		# Put hosts into assigned availability zone
		if [ "$HOST_ZONE" != "$ZONE" ]; then
			echo "Moving host $HOST from zone $HOST_ZONE to zone $ZONE..."
			openstack aggregate remove host $HOST_ZONE $HOST &> /dev/null
			openstack aggregate add host $ZONE $HOST &> /dev/null
		fi 
	done
done












