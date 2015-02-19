#/usr/bin/env bash
. /opt/stack/devstack/accrc/demo/demo
is_neutron=$(keystone catalog | grep "Service: network")
if [ "$is_neutron" ]; then
    # Google's public DNS server address
    dnsserver=8.8.8.8
    subnet=$(neutron subnet-list | grep private-subnet | grep start | awk -F "|" '{print $2}' | tr -d ' ')
    neutron subnet-update $subnet --dns-nameserver $dnsserver
    neutron subnet-show $subnet
fi
