#!/bin/bash
# Before this script:
# - Perform experiment:
#    - Ensure proper load generation on clients (VOD and IMS):
#        - vod/set-load.sh 0 && vod/set-load.sh 50
#        - clearwater/stop_sipp_stress.yml && clearwater/start_sipp_stress.sh
#    - Restart data collector containers
#    - data-collection/enable-data-collection.yml
#    - monitor-container-resources/start-monitoring-container-resource-usage.yml
#    - experiment-controller/start-experiments.yml
# - Stop experiment: experiment-controller/stop-experiments.yml
# - Stop data collection: data-collection/reset-collector-injector.yml, monitor-container-resources/stop-monitoring.yml
# - Download data: data-collection/fetch-data.yml (monitor-container-resources/fetch-monitoring-data.sh will be executed by the script below)
# - Optionally clean up data: data-collection/clean-remote-data.yml

# After this script:
# - Clean container resource data: monitor-container-resources/clean-remote-data.yml
# - Data in the local fetched data folder can be analysed: experiment-controller/evaluate-experiment.sh

home=`dirname $(readlink -e $0)`
ansible_root=$(readlink -e "$home/../..")

controller_ssh="wally181"
fetched_root="$HOME/fetched-data" # Default in scripts/data-collection/fetch-data.yml
controller_root="experiments" # Default in start-experiments.yml

controller_folder=$(ssh "$controller_ssh" "cd '$controller_root' && ls -t | head -1")
controller_folder="$controller_root/$controller_folder"
echo "Latest experiment folder on controller host: $controller_folder"

fetched_folder=$(cd "$fetched_root" && ls -t | head -1)
fetched_folder="$fetched_root/$fetched_folder"
echo "Latest fetched data folder locally: $fetched_folder"

read -r -d '' commands << EOF
    (cd "$fetched_folder" && mkdir -p experiment-controller hosts bitflow-collector ims vod brain);
    scp -r "$controller_ssh:$controller_folder/*" "$fetched_folder/experiment-controller/";
    cd "$ansible_root/scripts" && ./prepare-anomaly-analysis-data/extract-mapping-files.sh;
    cp -i "$ansible_root/ansible-inventory.ini" "$fetched_folder/hosts";
    (cd "$ansible_root/scripts/prepare-anomaly-analysis-data" && cp -i mapping-groups.json mapping-hosts.json mapping-anomalies.json "$fetched_folder/hosts");
    mv -i "$fetched_folder"/wally* "$fetched_folder/bitflow-collector"
    mv -i "$fetched_folder"/cw-sippstress* "$fetched_folder/ims"
    mv -i "$fetched_folder"/vod-client* "$fetched_folder/vod"
    "$ansible_root/scripts/monitor-container-resources/fetch-monitoring-data.yml" -e "fetch_dir=$fetched_folder"
    kubectl cp \$(kubectl get pod -l bitflow-step-name=a-brain -o jsonpath='{.items[0].metadata.name}'):/zerops/brain-logs/ "$fetched_folder/brain/"
EOF

echo -e "This script will execute the following commands:\n"
echo "$commands"
echo -e "\nPress enter to continue, or CTRL-C to cancel and manually execute commands\n"

read && eval "$commands"

