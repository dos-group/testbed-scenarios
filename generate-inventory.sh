#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

"$home/scripts/generate-ansible-inventory.sh" "$@" > "$home/ansible-inventory.ini"

test -f "$home/ansible-inventory-extra.ini" && cat "$home/ansible-inventory-extra.ini" >> "$home/ansible-inventory.ini"
