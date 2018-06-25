#!/bin/bash

home=`dirname $(readlink -e $0)`

ansible-playbook -i "$home/../Ansible/ansible-inventory.ini" $@ "$home/start-container-if-not-running.yml"
