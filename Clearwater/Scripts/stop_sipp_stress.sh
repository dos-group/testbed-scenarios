#!/bin/bash

ansible-playbook -i "$home/../Ansible/ansible-inventory.ini" "$home/stop_sipp_stress.yml"
