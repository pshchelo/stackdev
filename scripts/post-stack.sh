#! /usr/bin/env sh
testvm_url="http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img"
f20cloud_url="http://archive.fedoraproject.org/pub/alt/openstack/20/x86_64/Fedora-x86_64-20-20140618-sda.qcow2"
# Add latest Cirros amd64 qcow2 as public 'TestVM" image
. $HOME/devstack/accrc/admin/admin
glance image-create --progress --name TestVM --disk-format qcow2 --container-format bare --is-public True --location $testvm_url
# Create passwordless ssh key to access VMs
. $HOME/devstack/accrc/demo/demo
nova keypair-add demo > $HOME/demo.pem
chmod 600 $HOME/demo.pem

glance image-list
nova keypair-list
