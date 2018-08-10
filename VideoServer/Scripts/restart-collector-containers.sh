#!/bin/bash
home=`dirname $(readlink -e $0)`
cd "$home"

ansible $@ '!client' -b -m shell -a 'containers=$(docker ps -q --no-trunc --filter name=bitflow-collector); echo "Restarting $(echo "$containers" | wc -l) containers..."; for i in $containers; do docker restart $i; done'

