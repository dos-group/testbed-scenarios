
# This is a list of all virtual and physical hosts in the scenario, used by the other scripts

virtual_hosts_balancer="$(for i in 0 to 7; do echo "video-server-10-balancer-$i"; done)"
virtual_hosts_backend="$(for i in 0 to 19; do echo "video-server-10-video-$i"; done)"
virtual_hosts_client="$(for i in 0 to 7; do echo "video-server-10-client-$i"; done)"
virtual_hosts_core="$virtual_hosts_balancer $virtual_hosts_backend"
virtual_hosts="$virtual_hosts_core $virtual_hosts_client"
physical_hosts="$(for i in 183 192 193 194 195 197 198 199 200; do echo "wally$i.cit.tu-berlin.de"; done)"
all_core_hosts="$virtual_hosts_core $physical_hosts"
all_hosts="$virtual_hosts $physical_hosts"
