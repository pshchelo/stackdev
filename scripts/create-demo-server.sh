#!/usr/bin/env bash

# NOTE: expects the project in use to have keypair, network and security group
# named the same as project

set -e
server_name=$1
server_flavor=${2:-m1.nano}
server_image=${3:-Cirros-6.0}
project=$(openstack configuration show -f value -c auth.project_name)
script_dir=$(dirname "$0")
openstack server create "$server_name" \
    --key-name "$project" \
    --network "$project" \
    --security-group "$project" \
    --image "$server_image" \
    --flavor "$server_flavor" \
    --user-data "$script_dir/cirros-http-cpuload.userdata" \
    --use-config-drive \
    --wait

# NOTE: admin sees all FIPs by default, but non-admin always get empty FIP list
# when listing with project, even with their own, so need to differentiate
project_filter=""
if [ "$project" = "admin" ]; then
    project_filter="--project admin"
fi

# shellcheck disable=SC2086 # word splitting in project_filter is intentional
fip=$(openstack floating ip list $project_filter --status DOWN -f value -c 'Floating IP Address' | sort -R | head -n1)
if [ -z "$fip" ]; then
    fip=$(openstack floating ip create public -f value -c floating_ip_address)
fi
openstack server add floating ip "$server_name" "$fip"
