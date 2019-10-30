#!/bin/bash
home=`dirname $(readlink -e $0)`
cd "$home"
"../../Common/heat-create.sh" "video-server.yml" "video-server" $@
