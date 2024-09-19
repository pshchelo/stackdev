#!/usr/bin/env bash
stack=$1
computeN=$2
key2copy=${3:-aio}
stack_key=$(openstack stack resource list "$stack" -f value --filter type=OS::Nova::KeyPair -c physical_resource_id)
echo Duplicating key "$key2copy" to "$stack_key"
public_key=$(mktemp)
openstack keypair show "$key2copy" --public-key > "$public_key"
openstack keypair create "$stack_key" --public-key "$public_key"
rm "$public_key"
echo Updating stack "$stack" to have "$computeN" compute nodes
openstack stack update --existing "$stack" --parameter cmp_size="$computeN" --wait
