#!/bin/bash

#setup scenario file
new_scenario_file_url="https://raw.githubusercontent.com/bitflow-stream/testbed-scenarios/master/Clearwater/Docker/clearwater-docker/sip-stress/sip-stress-updated.xml"
#"https://raw.githubusercontent.com/bitflow-stream/testbed-scenarios/master/Clearwater/Docker/clearwater-docker/sip-stress/sip-stress-for-compute-node-stress.xml"
scenario_file_path="/usr/share/clearwater/sip-stress/sip-stress.xml"
rm $scenario_file_path   #remove existing scenario file
echo -e "Downloading scenario file...\n"
wget  -O $scenario_file_path "$new_scenario_file_url"

#configure users list
min_users=8000
max_users=12000
sip_stress_executable="/usr/share/clearwater/bin/sip-stress"
users_list_path="/usr/share/clearwater/sip-stress/users.csv.1"

complete_users_list="/usr/share/clearwater/sip-stress/complete_users.csv.1"
mv $users_list_path $complete_users_list

START_TIME=$(date +%s)
sip_stress_pid=""
while [ $(( $(date +%s) - 3600 )) -lt $START_TIME ]; do   #run this loop for one hour

    # after each round of stress is completed, run it again with different number of users   
    
    current_users_number=$(shuf -i $min_users-$max_users -n 1) #NUMBER=$[($RANDOM%4000)+8000]
    users_number=$current_users_number-1
    echo -e "Creating users list with $users_number users..."
    head -n $current_users_number $complete_users_list > $users_list_path

    #start test again...
    echo -e "Running SIP stress in background..."
    $sip_stress_executable &
    sip_stress_pid=$(echo $!)

    echo -e "SIP stress has PID: $sip_stress_pid"

    while [ -d "/proc/$sip_stress_pid" ];
    do
        sleep 10
    done

    #wait until this sip_stress is completed.. 
    
    #kill -9 "$sip_stress_pid" >/dev/null
done