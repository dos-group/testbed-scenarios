#!/bin/bash
home=`dirname $(readlink -e $0)`
cd "$home"
"../../../heat-common/heat-create.sh" "video-server.yml" "video-server" $@
