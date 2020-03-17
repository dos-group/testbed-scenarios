# Deployment of cloud workload scenarios and components of the ZerOps cloud platform

This repository contains deployment artifacts for:
- ZerOps data collector and anomaly injector
- Cloud workload: Project Clearwater (IMS, IP Multimedia Subsystem)
- Cloud workload: Video streaming server
- Various scripts to perform experiments on the ZerOps cloud platform

## Heat installation:
- In `projects/Clearwater/Heat` and `projects/VideoServer/Heat`, copy the respective `parameters.txt.template` file to `parameters.txt` and set the parameters to required values.
- Execute the two `create.sh` scripts in these directories. Requires sourcing of an `openrc` file first.
- Wait until the Heat stack are deployed

## Ansible orchestration:
- Copy `template-ansible-inventory-extra.ini` to `ansible-inventory-extra.ini` and adjust the contents to the testbed.
- Execute `generate-inventory.sh`, pass the name(s) of the created Heat stack(s) as parameter(s). Check the created `ansible-inventory.sh` for correctness.
- Enter the `playbooks` directory
- Execute the desired playbook(s): `./bootstrap.yml`, `./zerops.yml`, `./vod.yml`, `./clearwater.yml`
    - Limit the orchestration to only VMs or hypervisors by passing parameters to the playbooks: `-l vms` or `-l hypervisors`
