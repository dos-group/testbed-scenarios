#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

../../Common/Scripts/set_availability_zones.sh --cw_load 1 --cw_storage 2 --cw_core 6

