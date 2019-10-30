#!/bin/bash

[ -f create_homestead_cache.casscli ] || { 1>&2 echo "The create_homestead_cache.casscli file must be present on this system."; exit 1; }
[ -f create_homestead_provisioning.casscli ] || { 1>&2 echo "The create_homestead_provisioning.casscli file must be present on this system."; exit 1; }
cassandra-cli -B -f users.create_homestead_cache.casscli
cassandra-cli -B -f users.create_homestead_provisioning.casscli
