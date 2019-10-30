#!/bin/bash
# Homer bulk provisioning script for users in /tmp/7250.users.csv
# Run this script on any node in your Homer deployment to create the users
# The /tmp/7250.users.create_xdm.cqlsh file must also be present on this system

[ -f /tmp/7250.users.create_xdm.cqlsh ] || echo "The /tmp/7250.users.create_xdm.cqlsh file must be present on this system."
cqlsh -f /tmp/7250.users.create_xdm.cqlsh
