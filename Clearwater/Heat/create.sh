#!/bin/bash
case $# in
    0) HEAT_CMD="create"; NAME="clearwater";;
    1) HEAT_CMD="create"; NAME="$1";;
    2) HEAT_CMD="$1"; NAME="$2";;
    *) echo "Parameters: [command] [stack-name]"; exit 1;;
esac
HEAT_CMD="stack $HEAT_CMD"
echo "openstack $HEAT_CMD with name $NAME"

#create sub-dir for keys
mkdir -p keys
#Create key pair that will be used by the VMs to access each other
echo -e 'y\n' | ssh-keygen -q -t rsa -b 4096 -f keys/id_rsa -N '' 1>/dev/null

openstack $HEAT_CMD "$NAME" -t create-clearwater-vms.yml $(cat parameters.txt)
