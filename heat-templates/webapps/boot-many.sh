#!/usr/bin/env bash
set -ex
image=${1:-cirros}
flavor=${2:-m1.nano}

openstack network create demo
openstack subnet create demo --network demo --subnet-range 10.20.30.0/24
openstack router create demo
openstack router set demo --external-gateway public
openstack router add subnet demo demo
openstack security group create demo
openstack security group rule create demo --ingress --dst-port 8080 --protocol tcp
openstack security group rule create demo --ingress  --protocol icmp
# first test server
openstack server create trydemo --image $image --flavor $flavor --network demo --security-group demo --user-data ncweb.sh 
openstack server add floating ip trydemo $(openstack floating ip create public -f value -c name)
# and now a batch of 20
#openstack server create demo --image $image --flavor $flavor --network demo --security-group demo --user-data ncweb.sh --max 20
#for s in `openstack server list --name ^demo -f value -c ID`; do
#    openstack server add floating ip $s $(openstack floating ip create public -f value -c name)
#done
