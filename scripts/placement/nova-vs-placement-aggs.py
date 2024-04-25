#!/usr/bin/env python3
import argparse
import logging
import sys

import openstack
"""Find (and fix) descrepancies between nova and placement aggregates"""
prog_name = sys.argv[0]
parser = argparse.ArgumentParser(prog_name)
parser.add_argument("--fix", action="store_true")
parser.add_argument("-v", "--verbose", action="store_true")
args = parser.parse_args()
logging.basicConfig(
    level=logging.DEBUG if args.verbose else logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
LOG = logging.getLogger(prog_name)

cloud = openstack.connect()
nova = cloud.compute
placement = cloud.placement
placement.default_microversion = 1.1  # work with aggregates at all

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
    LOG.warning(
        f"Compute hosts that are not part of any aggregate: "
        f"{hosts_not_in_aggregates}"
    )

for agg in aggregates:
    for h in agg.hosts:
        host_rp = [rp for rp in resprovs if rp.name.startswith(h)]
        if not host_rp:
            if 'ironic' not in h:
                LOG.warning(
                    f"host {h} has no corresponding resource provider!"
                )
            continue
        host_rp = host_rp[0]
        rp_agg_url = [link['href'] for link in host_rp.links
                      if link['rel'] == 'aggregates'][0]
        rp_aggs = placement.get(rp_agg_url).json().get('aggregates')
        if agg.uuid not in rp_aggs:
            LOG.warning(
                f"host {h} is in nova aggregate {agg.name} == {agg.uuid} "
                f"but its resource provider {host_rp.id} is in placement "
                f"aggregates {rp_aggs}!"
            )
            if args.fix:
                try:
                    openstack.utils.pick_microversion(placement, "1.19")
                    req = {"aggregates": list(rp_aggs) + [agg.uuid],
                           "resource_provider_generation": host_rp.generation}
                except openstack.exceptions.SDKException:
                    req = list(rp_aggs) + [agg.uuid]
                placement.put(rp_agg_url, json=req)
                LOG.info(
                    f"added aggregate {agg.uuid} "
                    f"to resorce provider {host_rp.id}"
                )
