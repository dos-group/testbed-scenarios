#!/bin/bash

#run this as a service so that it can periodically check for the availability of astaire containers

LOG_FILE="/var/log/scale-astaire.log"
MEMCACHED_ETCD_KEY_URL="http://etcd:2379/v2/keys/clearwater/site1/node_type_memcached/clustering/memcached"
echo "########################### START ###########################" >> $LOG_FILE

#in start wait for other nodes to join
#sleep 300

memcached_cluster_info=$(curl -m 20 -L $MEMCACHED_ETCD_KEY_URL)

echo "$(date) $memcached_cluster_info" >> $LOG_FILE
values=$(echo $memcached_cluster_info | jq -r .node.value)
echo "$(date) Values in the ETCD are '$values'" >> $LOG_FILE
ips=$(echo $values | jq -r  'keys[]')
echo "$(date) Extracted IPs: ${ips[@]}" >> $LOG_FILE
is_value_changed=false
for i in ${ips[@]};
do
	echo "$(date) Pinging $i" >> $LOG_FILE
	ping -c3 -i1 $i 2>/dev/null 1>/dev/null
	if [ $? -ne "0" ]
	then
		echo "$(date) Could not ping IP $i. Hence, removing it from ETCD" >> $LOG_FILE
		values=$(echo "$values" | jq -r 'del(.['"\"$i\""'])')
		echo "$(date) New values so far are: '$values'" >> $LOG_FILE
		is_value_changed=true
	fi
done
if [ "$is_value_changed" = true ]; 
then
	echo "$(date) Posting updated values to ETCD. The values are: $values" >> $LOG_FILE
	curl -m 20 $MEMCACHED_ETCD_KEY_URL -XPUT -d value=$values
fi
echo "########################### END OF THE ITERATION ###########################" >> $LOG_FILE
