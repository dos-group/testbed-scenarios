#/bin/bash

#run this as a service so that it can periodically check for the availability of cassandra containers


while true;
do
	cassandra_cluster_info=$(curl -L http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra)

	values=$(echo $cassandra_cluster_info | jq -r .node.value)
	ips=$(echo $values | jq -r  'keys[]')
	unreachable_ips=()
	for i in $ips;
	do
		ping -c3 $i 2>/dev/null 1>/dev/null
		if [ $? -ne "0" ]
		then
			unreachable_ips+=($i)
		fi
	done
	for j in ${unreachable_ips[@]};
	do
		values=$(echo "$values" | jq -r 'del(.['"\"$j\""'])')

	done;

	if [[ ${unreachable_ips[@]} ]]; 
	then
		curl http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra -XPUT -d value=$values
	fi
	
	sleep 300
done