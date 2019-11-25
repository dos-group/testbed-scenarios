#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

test $# -lt 1 && { echo "Need at least 1 parameter: names heat stacks that should be added to the inventory"; exit 1; }

rm -f "$home/ansible-inventory.ini" &> /dev/null
for i in $@; do
    echo "Generating inventory for stack '$i'..."
    "$home/scripts/generate-project-inventory.sh" -p "$i" >> "$home/ansible-inventory.ini"
done

"$home/scripts/generate-project-inventory.sh" --hypervisors >> "$home/ansible-inventory.ini"

test -f "$home/ansible-inventory-extra.ini" && cat "$home/ansible-inventory-extra.ini" >> "$home/ansible-inventory.ini"
