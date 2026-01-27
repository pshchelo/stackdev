#!/usr/bin/env bash
dd if=/dev/random of=/tmp/random1k bs=1024 count=1
image_id=$(openstack image create random --file /tmp/random1k --disk-format raw --container-format bare --public -f value -c id)
rm /tmp/random1k
echo Image: "$image_id"
server_id=$(openstack server create --image "$image_id" --flavor m1.nano --no-network --wait random)
echo Server: "$server_id"
