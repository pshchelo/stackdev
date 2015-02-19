#!/usr/bin/env bash

# Allow WAN access for VMs
function allow_wan_access {
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

# Create passwordless ssh key to access VMs
function demo_keypair {
    . /opt/stack/devstack/accrc/demo/demo
    nova keypair-add demo > $HOME/demo.pem
    chmod 600 $HOME/demo.pem
    nova keypair-list
}

# Add Fedora 21 cloud image (needed for default AWS LoadBalancer resoure)
function add_awslb_image {
    . /opt/stack/devstack/accrc/admin/admin
    awslbimage_name="Fedora-Cloud-Base-20141203-21.x86_64"
    awslbimage_url="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/Fedora-Cloud-Base-20141203-21.x86_64.qcow2"
    glance image-create --progress --is-public True --disk-format qcow2 --container-format bare --location $awslbimage_url --name $awslbimage_name
}

# Assert the network service backend
function is_neutron {
    . /opt/stack/devstack/accrc/demo/demo
    keystone catalog | grep "Service: network"
}

# add Google's DNS server fo default subnet so that package managers
# can work from inside guests
function add_dns_neutron {
    . /opt/stack/devstack/accrc/demo/demo
    subnet=$(neutron subnet-list | grep private-subnet | grep start | awk -F "|" '{print $2}' | tr -d ' ')
    neutron subnet-update $subnet --dns-nameserver 8.8.8.8
    neutron subnet-show $subnet
}

function add_dns_nova {
    . /opt/stack/devstack/accrc/demo/demo
# TODO: add change similar dns net change for nova-network if needed
}

function fix_secgroup_neutron {
    . /opt/stack/devstack/accrc/demo/demo
# TODO: fix default security group by
# - removing existing ingress rules (they seem not to work)
# - adding ingress rules for ICMP and SSH
}

function fix_secgroup_nova {
    . /opt/stack/devstack/accrc/demo/demo
# TODO: add change similar secgroup change for nova-network if needed
}

function add_dns {
    if [ is_neutron ]; then
        add_dns_neutron
    else
        add_dns_nova
    fi
}

function fix_secgroup {
    if [ is_neutron ]; then
        fix_secgroup_neutron
    else
        fix_secgroup_nova
    fi
}

# Apply afterfixes
allow_wan_access
demo_keypair
add_awslb_image
add_dns
fix_secgroup
