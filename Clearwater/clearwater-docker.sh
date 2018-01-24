#!/bin/bash

command -v git >/dev/null 2>&1 || apt-get install git
# { echo >&2 "Git is not installed.  Please install git and then run the script again."; exit 1; }
git clone --recursive https://github.com/Metaswitch/clearwater-docker.git

command -v docker >/dev/null 2>&1 || { echo >&2 "Docker is not installed.  Please install docker and then run the script again."; exit 1;  }


cd clearwater-docker
docker build -t clearwater/base base

docker-compose -f minimal-distributed.yaml up -d

# cleanup
# rm ../clearwater-docker -r



