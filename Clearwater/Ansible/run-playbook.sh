#!/bin/bash
home=`dirname $(readlink -e $0)`
ansible-playbook "$home/playbook.yml" -i "$home/ansible-inventory.ini" $@
