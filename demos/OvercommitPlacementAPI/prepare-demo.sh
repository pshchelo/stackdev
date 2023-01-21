#!/usr/bin/env bash

# create a minimal flavor with max cpu possible
#openstack flavor create maxCPU --vcpus 8 --disk 1 --ram 128

# choose node to remove from cluster
#spare_node=$()
# disable compute node by delabeling it
#kubectl label node $spare_node openstack-compute-node-
# remove orphan compute service (would happen auto with cleanup job at some point?)
#openstack compute service delete $spare_node nova-compute
# wait/check that only one resource provider remains
#openstack resource provider list
# change its overcommit to 2
#openstack resource provider set --amend $first_resprov_id --resource VCPU:allocation_ratio=2
# set init allocation ratio to 2 as well for consistency
kubectl -n openstack patch osdpl osh-dev --type merge --patch '{"spec": {"features": {"nova": {"allocation_ratios": {"cpu": 2} }}}}'
# wait for it to be applied
until [ "$(kubectl get osdplst osh-dev -ojsonpath='{.status.osdpl.state}')" == "APPLYING" ]; do sleep 10; done
echo started applying...
until [ "$(kubectl get osdplst osh-dev -ojsonpath='{.status.osdpl.state}')" == "APPLIED" ]; do sleep 10; done
