#!/bin/bash
set -e
home=`dirname $(readlink -e $0)`

# Check if sudo pw is required
ANSIBLE_SUDO_ARG=""
if sudo -n true 2>/dev/null; then 
    echo "Sudo password not required."
else
    echo "Sudo password required."
    read -s -p “Sudo password: ” SUDO_PW
    ANSIBLE_SUDO_ARG="--extra-vars \"ansible_sudo_pass=$SUDO_PW\""
fi

LOCAL_INVENTORY="ansible-inventory-local.ini"
if [ ! -f "$home/$LOCAL_INVENTORY" ]; then
    echo -e "[load-balancer]" >>"$home/$LOCAL_INVENTORY"
    echo -e "localhost private_ip=0.0.0.0\n" >>"$home/$LOCAL_INVENTORY"
    echo -e "[client]" >>"$home/$LOCAL_INVENTORY"
    echo -e "localhost private_ip=0.0.0.0\n" >>"$home/$LOCAL_INVENTORY"
    echo -e "[backend]" >> "$home/$LOCAL_INVENTORY"
    echo -e "localhost private_ip=0.0.0.0\n" >>"$home/$LOCAL_INVENTORY"
    echo -e "[vms:children]" >>"$home/$LOCAL_INVENTORY"
    echo -e "load-balancer" >>"$home/$LOCAL_INVENTORY"
    echo -e "client" >>"$home/$LOCAL_INVENTORY"
    echo -e "backend" >>"$home/$LOCAL_INVENTORY"
fi

ansible-playbook $ANSIBLE_SUDO_ARG --skip-tags "bootstrap,injector,collector,load-balancer" -i "$LOCAL_INVENTORY" --connection=local playbook.yml
