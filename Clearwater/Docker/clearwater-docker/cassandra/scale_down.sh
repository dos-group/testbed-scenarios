#!/bin/bash

#run this as a service so that it can periodically check for the availability of cassandra containers

cassandra_cluster_info=$(curl -L http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra)
#echo "$(date) $cassandra_cluster_info"
values=$(echo $cassandra_cluster_info | jq -r .node.value)
ips=$(echo $values | jq -r  'keys[]')
is_value_changed=false
for i in $ips;
do
	ping -c3 $i 2>/dev/null 1>/dev/null
	if [ $? -ne "0" ]
	then
		values=$(echo "$values" | jq -r 'del(.['"\"$i\""'])')
		is_value_changed=true
	fi
done
if [ "$is_value_changed" = true ]; 
then
	curl http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra -XPUT -d value=$values
fi