#!/bin/bash

##INCOMPLETE

ansible-playbook ../Common/Ansible/install-docker.yml

ansible-playbook deploy_neo4j.yml --user ubuntu

EXIT_STATUS=$?

exit $EXIT_STATUS
