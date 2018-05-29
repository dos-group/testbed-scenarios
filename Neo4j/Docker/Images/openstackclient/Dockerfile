FROM ubuntu:16.04


LABEL Description="Openstack Client & Tools" Version="1.0"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages software-properties-common python-pip  nano
RUN pip install --upgrade pip
RUN pip install python-openstackclient
 
#later add service so that it can read from openstack and write to neo4j


CMD ["/bin/bash"]
