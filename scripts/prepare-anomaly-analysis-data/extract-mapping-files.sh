#!/bin/bash
home=`dirname $(readlink -e $0)`

# Extract info: { component-name: host-name }
echo "Creating file mapping-hosts.json"
ansible-inventory --list |\
jq -r '._meta.hostvars
    | with_entries( select((.value.host_type == "vm") or (.value.host_type == "hypervisor")) )
    | to_entries 
    | map(
        {(
             if .value.host_type == "hypervisor" 
             then .key 
             else .value.hypervisor+"-"+.value.libvirt_id 
             end
           ): .key 
        }) 
    | add
    ' > "$home/mapping-hosts.json"

function get_groups() {
    ANSIBLE_LOAD_CALLBACK_PLUGINS=1 ANSIBLE_STDOUT_CALLBACK=json \
        ansible $1 -m debug -a var=group_names | \
        jq -r '.plays[0].tasks[0].hosts | to_entries | .[0].value.group_names | .[]'
}

echo "Creating file mapping-groups.json and mapping-layers.json"
comma=""
echo "{" > "$home/mapping-groups.json"
echo "{" > "$home/mapping-layers.json"
for host in $(ansible hypervisors,vms --list | tail -n +2); do
    1>&2 echo "Getting main group of $host..."
    groups=$(get_groups "$host")
    component=""
    group=""
    layer=""
    if echo "$groups" | grep "hypervisors" &> /dev/null; then
        group="$host"
        component="$host"
        layer="physical"
    else
        group=$(echo "$groups" | egrep -v "anomaly-injector|clearwater|vms|docker-event-exposer|vod")
        component=$(ansible-inventory --host "$host" | jq -r '.hypervisor+"-"+.libvirt_id')
        layer="virtual"
    fi
    echo "$comma  \"$component\": \"$group\"" >> "$home/mapping-groups.json"
    echo "$comma  \"$component\": \"$layer\"" >> "$home/mapping-layers.json"

    comma="," # Start separating items after the first entry
done
echo "}" >> "$home/mapping-groups.json"
echo "}" >> "$home/mapping-layers.json"

