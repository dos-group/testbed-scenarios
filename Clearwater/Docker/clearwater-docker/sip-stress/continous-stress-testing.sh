#!/bin/bash

#setup scenario file
default_scenario_file="https://raw.githubusercontent.com/bitflow-stream/testbed-scenarios/master/Clearwater/Docker/clearwater-docker/sip-stress/sip-stress-updated.xml"
new_scenario_file_url=${1:-$default_scenario_file} 
min_users=${2:-8000}
max_users=${3:-12000}
time_span=${4:-3600}
user_list_duration=${5:-1800}

test $min_users -le $max_users || { echo -e "min_users must be less than max_users.\n"; exit 1; }

create_users() {
    current_users_number=$(shuf -i $1-$2 -n 1)
    users_number=$(($current_users_number-1))
    echo -e "Creating users list with $users_number users and writing it to the file $4..."
    head -n $current_users_number $3>$4
}


scenario_file_path="/usr/share/clearwater/sip-stress/sip-stress.xml"
rm $scenario_file_path   #remove existing scenario file
echo -e "Downloading scenario file..."
wget  -O $scenario_file_path "$new_scenario_file_url" >/dev/null

#configure users list
sip_stress_executable="/usr/share/clearwater/bin/sip-stress"
users_list_path="/usr/share/clearwater/sip-stress/users.csv.1"

complete_users_list="/usr/share/clearwater/sip-stress/complete_users.csv.1"
mv $users_list_path $complete_users_list


create_users $min_users $max_users $complete_users_list $users_list_path

start_time=$(date +%s)
echo -e "Starting time is: $(date -d @$start_time)"
sip_stress_pid=""
echo -e "------------------------------------------------"
while [ $(( $(date +%s) - $time_span )) -lt $start_time ]; do   #run this loop for one hour
    # after each round of stress is completed, run it again with different number of users 
    
    echo -e "New test is being started..."

    #change users number for certain file
    if [ $(date +%s) -ge $(( $start_time + $user_list_duration )) ]; 
    then
        create_users $min_users $max_users $complete_users_list $users_list_path
        user_list_duration=$(( $user_list_duration + $user_list_duration ))
    fi

    #start test...
    echo -e "Running SIP stress in background..."
    $sip_stress_executable & >/dev/null
    sip_stress_pid=$(echo $!) #getting PID because may be we need to do something withit.

    echo -e "SIP stress has PID: $sip_stress_pid"

    while [ -d "/proc/$sip_stress_pid" ];
    do
        sleep 60
    done

    #wait until this sip_stress is completed..sip-stress script waits by default for 60 seconds for the TCP connections to be timed-out
    #kill -9 "$sip_stress_pid" >/dev/null
    echo -e "------------------------------------------------"
done

exit 0