#!/bin/bash
set -e

declare -a injector_groups
injector_groups=(
    vms "../VideoServer/Ansible/ansible-inventory.ini" VOD
    vms "../Clearwater/Ansible/ansible-inventory.ini" IMS
    hypervisors "../Clearwater/Ansible/ansible-inventory.ini" HYPERVISORS
)

i=0
while [ $i -lt ${#injector_groups[@]} ]; do
    ansible_group="${injector_groups[$(( i+0 ))]}"
    inventory="${injector_groups[$(( i+1 ))]}"
    anomaly_group="${injector_groups[$(( i+2 ))]}"
    i=$((i+3))

    playbook_dir=$(dirname "$inventory")

    ansible_hosts=$(ansible -i "$inventory" "$ansible_group" --list-hosts | sort | tail +2)
    for host in $ansible_hosts; do
        info=$(ansible-inventory --playbook-dir="$playbook_dir" --host "$host" -i "$inventory")

        port=$(echo "$info" | jq -r .injector.api_port)
        test -z "$port" -o "$port" = "null" && port=7888

        echo "  - name: $host
    endpoint: http://$(echo "$info" | jq -r .ansible_host):$port
    anomalyGroups: *$anomaly_group"
    done
done

