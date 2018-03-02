#/bin/bash


#Not properly tested yet. Also, run this as a service so that it can periodically check for the availability of cassandra containers

cassandra_cluster_info=$(curl -L http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra)

values=$(echo $cassandra_cluster_info | jq -rM .node.value)

ips=$(echo $values | jq 'keys[]')

unreachable_ips=()
for i in $ips;
do
	ping -c3 $i 2>/dev/null 1>/dev/null
	if [ "$?" != 0 ]
	then
		unreachable_ips+=($i)
	fi
done

for i in ${unreachable_ips[@]};
do
	values=$(echo $values | jq 'del(."$i")')
done;

if [[ ${array[@]} ]]; 
then
	curl http://etcd:2379/v2/keys/clearwater/node_type_cassandra/clustering/cassandra -XPUT -d value=$values
fi


exit 0
