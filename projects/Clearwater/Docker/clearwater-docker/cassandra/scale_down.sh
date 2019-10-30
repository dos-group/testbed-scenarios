#!/bin/bash

#run this as a service so that it can periodically check for the availability of cassandra containers
echo "########################### START ###########################" >> /var/log/scale-down-cassandra.log

#in start wait for other nodes to join
sleep 300

cassandra_cluster_info=$(curl -m 20 -L http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra)

echo "$(date) $cassandra_cluster_info" >> /var/log/scale-down-cassandra.log
values=$(echo $cassandra_cluster_info | jq -r .node.value)
echo "$(date) Values in the ETCD are '$values'" >> /var/log/scale-down-cassandra.log
ips=$(echo $values | jq -r  'keys[]')
echo "$(date) Extracted IPs: ${ips[@]}" >> /var/log/scale-down-cassandra.log
is_value_changed=false
for i in ${ips[@]};
do
	echo "$(date) Pinging $i" >> /var/log/scale-down-cassandra.log
	ping -c3 -i1 $i 2>/dev/null 1>/dev/null
	if [ $? -ne "0" ]
	then
		echo "$(date) Could not ping IP $i. Hence, removing it from ETCD" >> /var/log/scale-down-cassandra.log
		values=$(echo "$values" | jq -r 'del(.['"\"$i\""'])')
		echo "$(date) New values so far are: '$values'" >> /var/log/scale-down-cassandra.log
		is_value_changed=true
	fi
done
if [ "$is_value_changed" = true ]; 
then
	echo "$(date) Posting updated values to ETCD. The values are: $values" >> /var/log/scale-down-cassandra.log
	curl -m 20 http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra -XPUT -d value=$values
fi
echo "########################### END OF THE ITERATION ###########################" >> /var/log/scale-down-cassandra.log
