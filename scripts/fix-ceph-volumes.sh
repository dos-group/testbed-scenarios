#!/bin/bash

# This script helps fixing an issue with VMs that use Ceph-backed volumes and have been shut down unexpectedly, for example by rebooting the hypervisor.
# When booting VMs on such a hypervisor, they show lines like this on the console:
#
# [    4.777441] Buffer I/O error on dev vda1, logical block 524293, lost async page write
# [    4.792629] blk_update_request: I/O error, dev vda, sector 4212512
#
# This is because a Ceph lock for the VMs volume was not removed due to the sudden shutdown.
# This script prints a command that removes the lock. After this command, the VM can be restarts and should boot normally.
#
# Another symptom of the same problem is that accessing the swap does not work as well.
# This only shows when the VM actually attempts to access swap... Then it prints message like "write error on swap device"
# This script attempts to find swap devices associated with the VM as well.

# Access ceph_mon container on this node. Alternative would be to use local Ceph client and connect remotely.
ceph_node="wally184"

instance="$1"
test $# = 1 -o -e "$instance" || { echo "Need 1 parameter: instance name to clear the Ceph volume ID for"; exit 1; }

echo "Getting volume ID for instance '$instance'..."
volume_id=$(openstack server show -f value -c volumes_attached "$instance" | head -1)
volume_id=${volume_id:4:-1}
test -e "$volume_id" && { echo "Failed to query volume ID"; exit 1; }
echo "Volume ID: $volume_id"

echo "Getting instance ID for instance '$instance'..."
instance_id=$(openstack server show -f value -c id "$instance" | head -1)
test -e "$instance_id" && { echo "Failed to query instance ID"; exit 1; }
echo "Instance ID: $instance_id"

function print_ceph_info() {
    image="$1"
    echo "Getting volume lock info for volume '$image' from Ceph on $ceph_node..."
    lock_info=$(ssh "$ceph_node" "docker exec ceph_mon rbd lock ls '$image' --format json" | tail -1)
    if [ -e "$lock_info" ]; then
        echo "!!! Failed to query lock info."
    else
        echo "Volume lock info: $lock_info"

        lock_id=$(echo "$lock_info" | jq -r keys[0]'')
        echo "Volume lock ID: $lock_id"
        locker=$(echo "$lock_info" | jq -r ".[\"$lock_id\"].locker")
        echo "Volume locker: $locker"

        if [ "$lock_id" = "null" -o "$locker" = "null" -o "$lock_id" = "" -o "$locker" = "" ]; then
            echo "!!! Lock ID or locker name is null or empty, it seems either the image does not exist, or it is not locked: $image"
        else
            echo -e "\n====== Execute the following command to remove the Ceph lock for $image:"
            echo -e "ssh $ceph_node docker exec ceph_mon \"rbd lock rm '$image' '$lock_id' '$locker'\"\n"
        fi
    fi
}

print_ceph_info "volumes/volume-$volume_id"
print_ceph_info "vms/${instance_id}_disk"
print_ceph_info "vms/${instance_id}_disk.swap"

echo -e "\n====== After unlocking the Ceph volume(s), execute the following to reboot the instance:\n"
echo "openstack server reboot --hard '$instance'"

