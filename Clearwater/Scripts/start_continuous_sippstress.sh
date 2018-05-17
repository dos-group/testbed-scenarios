#!/bin/bash

home=`dirname $(readlink -e $0)`

test $# -ge 2 || { echo -e "Need at least 2 parameters (path to key file and endpoint where the sipp stress container is running).\n"; exit 1; }

KEY_FILE=$1
ENDPOINT=$2
SIP_STRESS_CONTAINER_NAME=${3:-'sip-stress'}

CMD="sudo docker ps --format \"{{ .Names }}\" | grep $SIP_STRESS_CONTAINER_NAME | tr '\n' '\0' | xargs -0t -I {} sudo docker exec -t {} /bin/bash -s"

ssh -i $KEY_FILE -o StrictHostKeyChecking=no \
    -A ubuntu@$ENDPOINT "bash -s $CMD" < "$home/test.sh"
    
    
    
    #bash -s' < "$home/docker-swarm-initialize-remote.sh"
