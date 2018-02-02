#!/bin/bash
# Delete all collected data on remote hosts by restarting the data collection services.
# This should be done after calling ./fetch.sh to avoid fetching redundant data.
home=`dirname $(readlink -e $0)`

source "$home/hosts.sh"

ansible-playbook "../VideoServer/Ansible/reset-collector-injector.yml" -i "../VideoServer/Ansible/ansible-inventory.ini"

for i in $all_core_hosts; do
    echo " >>> Cleaning data-collection files on $i..."
    ssh -i $1 "ubuntu@$i" "sudo rm /opt/bitflow/data-collector/data*.bin"
done

