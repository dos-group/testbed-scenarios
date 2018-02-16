#!/bin/bash

# Work in the current directory
home="."

HEAT_TEMPLATE="$1"
DEFAULT_NAME="$2"
shift 2

case $# in
    0) HEAT_CMD="create"; NAME="$DEFAULT_NAME";;
    1) HEAT_CMD="create"; NAME="$1";;
    2) HEAT_CMD="$1"; NAME="$2";;
    3) HEAT_CMD="$1"; NAME="$2"; EXISTING="$3";;
    *) echo "Parameters: [command] [stack-name] [--existing]"; exit 1;;
esac

PARM="$home/parameters.txt"
test -e "$PARM" || { echo "The required file '$PARM' does not exist. Create it based on 'parameters.txt.template'"; exit 1; }

HEAT_CMD="stack $HEAT_CMD"
echo "openstack $HEAT_CMD with name $NAME"

# Create sub-dir for keys
KEYS="$home/keys"
mkdir -p "$KEYS"
# Create key pair that will be used by the VMs to access each other
echo -e 'y\n' | ssh-keygen -q -t rsa -b 4096 -f "$KEYS/id_rsa" -N '' 1>/dev/null

if [ -z $EXISTING ]; then
    openstack $HEAT_CMD "$NAME" -t "$HEAT_TEMPLATE" $(cat "$PARM")
else
    openstack $HEAT_CMD "$NAME" "$EXISTING" $(cat "$PARM")
fi
