#!/usr/bin/env bash
. /opt/stack/devstack/accrc/demo/demo
is_neutron=$(keystone catalog | grep "Service: network")
if [ "$is_neutron" ]; then
    neutron security-group-rule-list -f csv -c id -c security_group -c direction | grep 'default.*ingress' | awk -F "," '{print $1}' | xargs -L1 neutron security-group-rule-delete
    neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol ICMP
    neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol TCP --port-range-min 22 --port-range-max 22
fi

