#!/usr/bin/env python3
import openstack
"""Find descrepancies between nova and placement aggregates"""
cloud = openstack.connect()
nova = cloud.compute
placement = cloud.placement
placement.default_microversion = 1.39

aggregates = list(nova.aggregates())
computes = list(nova.services(binary='nova-compute'))
resprovs = list(placement.resource_providers())

hosts_in_aggregates = []
for agg in aggregates:
    hosts_in_aggregates.extend(agg.hosts)

hosts_not_in_aggregates = (
    set(s.host for s in computes) - set(hosts_in_aggregates)
)
if hosts_not_in_aggregates:
    print("Compute hosts that are not part of any aggregate:")
    for host in hosts_not_in_aggregates:
        print(host)

for agg in aggregates:
    for h in agg.hosts:
        host_rp = [rp for rp in resprovs if rp.name.startswith(h)]
        if not host_rp:
            if 'ironic' not in h:
                print(f"host {h} has no corresponding resource provider!")
            continue
        host_rp = host_rp[0]
        rp_agg_url = [link['href'] for link in host_rp.links
                      if link['rel'] == 'aggregates'][0]
        rp_aggs = placement.get(rp_agg_url).json().get('aggregates')
        if agg.uuid not in rp_aggs:
            print(f"host {h} is in nova aggregate {agg.name} == {agg.uuid} "
                  f"but its resource provider {host_rp.id} is in placement "
                  f"aggregates {rp_aggs}!")
