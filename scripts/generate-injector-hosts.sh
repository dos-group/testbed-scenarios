#!/bin/bash
set -e

vms_component_jq_query='.hypervisor + "-" + .libvirt_id'

declare -a injector_groups
injector_groups=(
    load-balancer VOD "$vms_component_jq_query"
    backend VOD "$vms_component_jq_query"
    #client VOD "$vms_component_jq_query"

    sprout IMS "$vms_component_jq_query"
    bono IMS "$vms_component_jq_query"
    cassandra IMS "$vms_component_jq_query"
    homer IMS "$vms_component_jq_query"
    homestead IMS "$vms_component_jq_query"
    ralf IMS "$vms_component_jq_query"
    chronos IMS "$vms_component_jq_query"
    astaire IMS "$vms_component_jq_query"
    #etcd IMS "$vms_component_jq_query"
    #sippstress IMS "$vms_component_jq_query"
    #ellis IMS "$vms_component_jq_query"
    #swarm_manager IMS "$vms_component_jq_query"
    #homesteadprov IMS "$vms_component_jq_query"

    hypervisors HYPERVISORS ""
)

i=0
while [ $i -lt ${#injector_groups[@]} ]; do
    ansible_group="${injector_groups[$(( i+0 ))]}"
    anomaly_group="${injector_groups[$(( i+1 ))]}"
    component_jq_string="${injector_groups[$(( i+2 ))]}"
    i=$((i+3))

    echo \
"  - name: $ansible_group
    anomalyGroups: *$anomaly_group
    endpoints:"

    ansible_hosts=$(ansible "$ansible_group" --list-hosts | sort | tail +2)
    for host in $ansible_hosts; do
        info=$(ansible-inventory --host "$host")

        port=$(echo "$info" | jq -r .injector.api_port)
        test -z "$port" -o "$port" = "null" && port=7888

        component="$host"
        if [ -n "$component_jq_string" ]; then
            component=$(echo "$info" | jq -r "$component_jq_string")
        fi

        echo \
"      - !!anomaly.experiment.controller.objects.Endpoint
        name: $host
        endpoint: http://$(echo "$info" | jq -r .ansible_host):$port
        component: $component"

    done
done
