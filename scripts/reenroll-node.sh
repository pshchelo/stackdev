#!/usr/bin/env bash
. /opt/stack/devstack/openrc admin admin

old_node_id=`ironic node-list --fields uuid name | grep $1 | awk '{print $2}'`
node_mac=`ironic port-list --fields address uuid node_uuid | grep $old_node_id | awk '{print $2}'`
node_driver=`ironic node-show $1 --fields driver | grep driver | awk '{print $4}'`
ironic node-delete $old_node_id
node_id=`ironic --ironic-api-version latest node-create -n $1 -d $node_driver | grep -w uuid | awk '{print $4}'`
ironic port-create -a $node_mac -n $node_id
