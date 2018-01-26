#!/bin/bash

#check if docker is running
sudo docker ps &> /dev/null || sudo service docker restart

# check if $SWARM_LEADER_PRIVATE has ip then use this otherwise get ip
export LEADER_PRIVATE_IP=${LC_SWARM_LEADER_PRIVATE:-$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)}  #in case if the env has any consfusion about current private ip

#check if swarm is already running.if yes then dont execute the following init command
IS_ALREADY_RUNNING=$(sudo docker node list -q)
if [ -z "$IS_ALREADY_RUNNING" ]; then
	#init
	echo "Initializing swarm..."
	sudo docker swarm init --advertise-addr $LC_SWARM_LEADER_PRIVATE:2377 #--listen-addr $LC_SWARM_LEADER_PRIVATE:2377 --advertise-addr $LC_SWARM_LEADER_PRIVATE:2377
else
	echo "The leader node is already part of the swarm."
fi

#get swarm tokens
export LC_MANAGER_TOKEN=$(sudo docker swarm join-token manager -q)
export LC_WORKER_TOKEN=$(sudo docker swarm join-token worker -q)

LC_NODE_PRIVATE_IPS=($LC_ETCD_PRIVATE_IPS $LC_ELLIS_PRIVATE_IPS $LC_BONO_PRIVATE_IPS $LC_SPROUT_PRIVATE_IPS $LC_HOMER_PRIVATE_IPS $LC_HOMESTEAD_PRIVATE_IPS $LC_CASSANDRA_PRIVATE_IPS $LC_ASTAIRE_PRIVATE_IPS $LC_HOMESTEADPROV_PRIVATE_IPS $LC_CHRONOS_PRIVATE_IPS $LC_RALF_PRIVATE_IPS $LC_SIPP_STRESS_PRIVATE_IPS)
for k in ${LC_NODE_PRIVATE_IPS[@]};
do
	echo "Adding $k to the swarm as a worker..."
	ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes -o SendEnv="LC_WORKER_TOKEN LC_SWARM_LEADER_PRIVATE" ubuntu@$k "sudo docker swarm join --token $LC_WORKER_TOKEN $LC_SWARM_LEADER_PRIVATE:2377 &> /dev/null";
done

echo "Labeling nodes..."
HOSTNAMES=$(sudo docker node ls --format "{{.Hostname}}")
for name in $HOSTNAMES;
do
	echo "Labeling: $name"
	{sudo docker node update --label-add comp=$(echo "$name"|cut -d- -f1) $name } &> /dev/null
done

echo "Creating Clearwater stack..."

sudo -E docker stack deploy -c ~/docker-compose.yaml clearwater_stack --with-registry-auth

# tell swarm managers to join leader
# do it AFTER stack deploy since it deployment causes a lot of load on the swarm leader
# due to the load, the leader sometimes gets reelected to some other --> the deployment does not finsh
LC_REACHABLE_MANAGER_PRIVATE_IPS=$(echo "$LC_REACHABLE_MANAGER_PRIVATE_IPS"|jq -r '.[]') 
for j in $LC_REACHABLE_MANAGER_PRIVATE_IPS;
do
    echo "Adding $j to the swarm as a manager..."
    ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes -o SendEnv="LC_MANAGER_TOKEN LC_SWARM_LEADER_PRIVATE" ubuntu@$j "sudo docker swarm join --token $LC_MANAGER_TOKEN $LC_SWARM_LEADER_PRIVATE:2377 &> /dev/null";
done

exit 0
