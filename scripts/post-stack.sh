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

# Add a DNS server fo default Neutron subnet so that package managers
# can work from inside guests
function add_dns {
    . /opt/stack/devstack/accrc/demo/demo
    is_neutron=$(keystone catalog | grep "Service: network")
    if [ "$is_neutron" ]; then
        # Google's public DNS server address
        dnsserver=8.8.8.8
        subnet=$(neutron subnet-list | grep private-subnet | grep start | awk -F "|" '{print $2}' | tr -d ' ')
        neutron subnet-update $subnet --dns-nameserver $dnsserver
        neutron subnet-show $subnet
    fi
}

# Delete existing ingress rules in default Neutron security group
# and add ingress rules for ICMP and SSH
function fix_secgroup {
    . /opt/stack/devstack/accrc/demo/demo
    is_neutron=$(keystone catalog | grep "Service: network")
    if [ "$is_neutron" ]; then
        neutron security-group-rule-list -f csv -c id -c security_group -c direction | grep 'default.*ingress' | awk -F "," '{print $1}' | xargs -L1 neutron security-group-rule-delete
        neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol ICMP
        neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol TCP --port-range-min 22 --port-range-max 22
    fi
}

# Apply afterfixes
allow_wan_access
demo_keypair
add_awslb_image
add_dns
fix_secgroup
