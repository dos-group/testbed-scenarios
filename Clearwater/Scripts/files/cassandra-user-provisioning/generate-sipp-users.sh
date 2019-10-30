#!/bin/bash

num_users=${1:-50000}
top_number=$(expr 2010000000 + $num_users - 1)

home_domain="example.com"
password="7kkzTyGW"

rm -f sipp-users.csv 2> /dev/null
for DN in $(seq 2010000000 $top_number); do
    echo "sip:$DN@$home_domain,$DN@$home_domain,$home_domain,$password" >> sipp-users.csv
done
