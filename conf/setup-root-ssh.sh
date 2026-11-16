#!/usr/bin/env bash

# Set up root ssh access between devstack controller and compute nodes.
# Run this script on the devstack compute node.
# Pre-requisites:
# - local.conf for this compute is prepared
# - SSH access for the user running this script in both directions between controller and compute
# - passwordless sudo for the user running this script on both controller and compute

set -e
DEVSTACK_DIR="$HOME/Projects/openstack/devstack"
IFACE='ens3'

# discover controller IP from prepared devstack config
eval "$(grep ^SERVICE_HOST "$DEVSTACK_DIR/local.conf")"

# add controller to /etc/hosts on compute
controller_hostname=$(ssh "$SERVICE_HOST" -- hostname)
echo "$SERVICE_HOST $controller_hostname" | sudo tee -a /etc/hosts
# add compute to /etc/hosts on controller
compute_hostname=$(hostname)
compute_ip=$(ip a show dev "$IFACE" | grep 'inet ' | awk '{print $2}' | awk -F '/' '{print $1}')
ssh "$SERVICE_HOST" -- sudo sh -c "echo $compute_ip $compute_hostname >> /etc/hosts"

# prepare files and scripts to patch root SSH config and copy SSH keys to root user
cat /tmp/root_ssh_config << EOF
IdentitiesOnly yes
User ubuntu
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
LogLevel QUIET
EOF
cat /tmp/root_ssh_config.sh << EOF
sudo mv /tmp/root_ssh_config /root/.ssh/config
for key in "${HOME}"/.ssh/id_*; do
    if [[ "\$key" != *pub ]]; then
        sudo cp "\$key" /root/.ssh/
        echo "IdenityFile /root/.ssh/\$(basename "\$key")" | sudo tee -a /root/.ssh/config
    fi
done
rm /tmp/root_ssh_config.sh
EOF
# upload root SSH related files and sript to controller
scp /tmp/root_ssh_config "${SERVICE_HOST}:/tmp/root_ssh_config"
scp /tmp/root_ssh_config.sh "${SERVICE_HOST}:/tmp/root_ssh_config.sh"

# patch root SSH on compute
bash /tmp/root_ssh_config.sh
# patch root SSH on controller
ssh "${SERVICE_HOST}" -- bash /tmp/root_ssh_config.sh
