#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

test $# = 1 || { echo "Need 1 parameter: name of the stack to generate the inventory for"; exit 1; }
STACK="$1"

"$home/../../Common/Ansible/generate-ansible-inventory.sh" "$STACK" > "$home/ansible-inventory.ini"

test -f "$home/ansible-inventory-extra.ini" && cat "$home/ansible-inventory-extra.ini" >> "$home/ansible-inventory.ini"

