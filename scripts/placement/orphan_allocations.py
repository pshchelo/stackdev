#!/usr/bin/env python3
"""
Find and optionally delete Placement allocations for which consumer
does not exist as an instance/server in Nova.
"""
import argparse
import json
import logging
import openstack
parser = argparse.ArgumentParser()
parser.add_argument("-v", "--verbose", action="store_true")
parser.add_argument("-d", "--delete", action="store_true")
args = parser.parse_args()
logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s')
LOG = logging.getLogger("orphan-allocations")
if args.verbose:
    LOG.setLevel(logging.DEBUG)
cloud = openstack.connect()
orphans = []
for rp in sorted(cloud.placement.resource_providers(), key=lambda x: x.name):
    LOG.debug(f"Checking resource provider {rp.id}/{rp.name}")
    allocations = cloud.placement.get(
        f"/resource_providers/{rp.id}/allocations"
    ).json()["allocations"]
    for consumer, alloc in allocations.items():
        resources = alloc["resources"]
        if not set(resources).issubset({"VCPU", "MEMORY_MB", "DISK_GB"}):
            LOG.warning(
                f"strange consumer {consumer} on resource provider {rp.id}: "
                f"{alloc}")
            continue
        if not cloud.compute.find_server(consumer, all_projects=True):
            LOG.info(
                f"Server {consumer} does not exist"
            )
            orphans.append({"server_id": consumer})
            if args.delete:
                resp = cloud.placement.delete(f"/allocations/{consumer}")
                if resp.status_code not in (204, 404):
                    LOG.warning(
                        f"Failed to delete allocations for consumer {consumer}"
                    )
                    orphans.pop(-1)
                else:
                    LOG.info(f"Deleted allocations for consumer {consumer}")
if orphans:
    if args.delete:
        print("deleted {len(orphans)} orphan allocations")
    else:
        print(json.dumps({"orphans": orphans}, indent=4))
