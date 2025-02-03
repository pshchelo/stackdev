#!/usr/bin/env bash
stack=$1
computes=$2
if [ -z "$stack" ] || [ -z "$computes" ]; then
    echo "Provide the stack name or ID and target number of compute nodes"
    exit 1
fi
stack_key=$(openstack stack resource list "$stack" -f value --filter type=OS::Nova::KeyPair -c physical_resource_id)
echo "Duplicating key $stack_key"
public_key=$(mktemp)
openstack stack show "$stack" -f value -c parameters | jq -r .cluster_public_key > "$public_key"
openstack keypair create "$stack_key" --public-key "$public_key"
rm "$public_key"
echo "Updating stack $stack to have $computes compute nodes"
openstack stack update --existing "$stack" --parameter cmp_size="$computes" --wait
