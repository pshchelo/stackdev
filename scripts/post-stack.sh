#!/usr/bin/env sh

# Assert the network service backend
function is_neutron {
    . /opt/stack/devstack/accrc/demo/demo
    keystone catalog | grep "Service: network"
}

# Create passwordless ssh key to access VMs
function demo_keypair {
    . /opt/stack/devstack/accrc/demo/demo
    nova keypair-add demo > $HOME/demo.pem
    chmod 600 $HOME/demo.pem
    nova keypair-list
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
# TODO: fix default security group by adding pings and ssh into ingress
# and everything to egress
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
demo_keypair
add_dns
fix_secgroup
