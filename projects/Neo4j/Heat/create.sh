#!/bin/bash
home=`dirname $(readlink -e $0)`
cd "$home"
"$home/../../Common/heat-create.sh" "$home/neo4j.yml" "neo4j" $@