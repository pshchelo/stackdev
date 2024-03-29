#!/usr/bin/env bash
stack="$1"
for server in $(openstack stack resource list -n9 --filter type=OS::Nova::Server -f value -c physical_resource_id "${stack}"); do
    echo -n "$server   "
    openstack server ssh "$server" -- -l ubuntu -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/aio_rsa -o LogLevel=ERROR -- top -bn1 | head | grep st$ | awk -F ',' '{print $NF}'
done
