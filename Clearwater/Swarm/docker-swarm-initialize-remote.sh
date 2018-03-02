#!/bin/bash
# Expected environment variables in this script:
# LC_STACK_NAME: Name of the stack to create from ~/docker-compose.yaml
# LC_INITIAL_MANAGER: Private IP of this node
# LC_OTHER_MANAGERS: Space separated list of IPs of other Swarm managers
# LC_WORKERS: Space separated list of IPs of Swarm workers


#export advanced parameters
export ADDITIONAL_SHARED_CONFIG="diameter_timeout_ms=600\nsprout_homestead_timeout_ms=550\nralf_threads=300\ndns_timeout=400"
 
#check if docker is running
sudo docker ps &> /dev/null || sudo service docker restart

# check if $SWARM_LEADER_PRIVATE has ip then use this otherwise get ip
export LC_INITIAL_MANAGER=${LC_INITIAL_MANAGER:-$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)}  #in case if the env has any consfusion about current private ip

#check if swarm is already running.if yes then dont execute the following init command
IS_ALREADY_RUNNING=$(sudo docker node list -q)
if [ -z "$IS_ALREADY_RUNNING" ]; then
	echo "Initializing swarm..."
	sudo docker swarm init --advertise-addr $LC_INITIAL_MANAGER:2377 #--listen-addr $LC_INITIAL_MANAGER:2377 --advertise-addr $LC_INITIAL_MANAGER:2377
else
	echo "The leader node is already part of the swarm."
fi

#get swarm tokens
export LC_MANAGER_TOKEN=$(sudo docker swarm join-token manager -q)
export LC_WORKER_TOKEN=$(sudo docker swarm join-token worker -q)

for k in $LC_WORKERS; do
	echo "Adding $k to the swarm as a worker..."
	ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes -o SendEnv="LC_WORKER_TOKEN LC_INITIAL_MANAGER" ubuntu@$k "sudo docker swarm join --token $LC_WORKER_TOKEN $LC_INITIAL_MANAGER:2377 &> /dev/null";
done

for j in $LC_OTHER_MANAGERS; do
	echo "Adding $j to the swarm as a manager..."
	ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes -o SendEnv="LC_MANAGER_TOKEN LC_INITIAL_MANAGER" ubuntu@$j "sudo docker swarm join --token $LC_MANAGER_TOKEN $LC_INITIAL_MANAGER:2377 &> /dev/null"
done

echo "Labeling nodes..."
HOSTNAMES=$(sudo docker node ls --format "{{.Hostname}}")
for name in $HOSTNAMES; do
	echo "Labeling: $name"
    { sudo docker node update --label-add comp=$(echo "$name" | cut -d- -f2) $name ; } &> /dev/null
done

echo "Launching stack '$LC_STACK_NAME'..."
sudo -E docker stack deploy -c ~/docker-compose.yaml "$LC_STACK_NAME" --with-registry-auth


