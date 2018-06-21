#!/bin/bash

home=`dirname $(readlink -e $0)`

ansible-playbook -i "$home/../Ansible/ansible-inventory.ini" "$home/stop_sipp_stress.yml"
