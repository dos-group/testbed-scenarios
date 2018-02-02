#!/bin/bash

test $# = 1 || { echo "Need 1 parameter: Percent (0..1) of load"; exit 1; }
target_load=$1



# ansible-playbook update-load-targets.yml

