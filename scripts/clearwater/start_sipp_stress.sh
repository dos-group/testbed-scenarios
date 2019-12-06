#!/bin/bash
home=`dirname $(readlink -e $0)`

duration=36000000
t_load_change=1200
min_users=5000
max_users=8000

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -d|--duration) duration="$2"; shift 2 ;;
        --min_users) min_users="$2"; shift 2 ;;
        --max_users) max_users="$2"; shift 2 ;;
        --t_load_change) t_load_change="$2"; shift 2 ;;
        *) echo "Unknown parameter: $key"; exit -1 ;;
    esac
done

load_args="\"--min_users $min_users --max_users $max_users -d $duration --t_load_change $t_load_change\""
echo "Using load_args: $load_args"

"$home/start_sipp_stress.yml" -e "load_args=$load_args" 
