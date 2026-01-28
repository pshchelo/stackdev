#!/usr/bin/env bash
set -e
name="random"
dd if=/dev/random of=/tmp/random1k bs=1024 count=1 status=none
image_id=$(openstack image create "$name" --file /tmp/random1k --disk-format raw --container-format bare --public -f value -c id)
rm /tmp/random1k
echo Image: "$name" "$image_id"
server_id=$(openstack server create "$name" --image "$image_id" --flavor m1.nano --no-network --wait -f value -c id)
echo Server: "$name" "$server_id"
