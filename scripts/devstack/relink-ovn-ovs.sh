#!/usr/bin/env bash

# Fix ovn+ovs re-occurent devstack problem "ovn_db.socket not found"
# unstack, run this script, stack again.
sudo rm -rf /var/run/openvswitch
sudo rm -rf /var/run/ovn

sudo mkdir /var/run/openvswitch
sudo ln -s /var/run/openvswitch /var/run/ovn
