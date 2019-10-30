#!/bin/bash

ansible hypervisors -b -m shell -a 'docker exec -i injector tcshow -d enp2s0'
ansible hypervisors -b -m shell -a 'docker exec -i injector tcshow -d eno1'
ansible vms:!sippstress:!etcd:!swarm_manager -b -m shell -a 'docker exec -i injector tcshow -d ens3'
