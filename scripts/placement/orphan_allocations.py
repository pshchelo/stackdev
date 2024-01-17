#!/usr/bin/env python3
"""
Find and delete Placement allocations for which consumer does not exist
as an instance/server in Nova.
"""
import logging
import openstack
logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s')
LOG = logging.getLogger("orphan-allocations")
LOG.setLevel(logging.DEBUG)
cloud = openstack.connect()
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
            LOG.debug(
                f"Server {consumer} does not exist, deleting allocations"
            )
            resp = cloud.placement.delete(f"/allocations/{consumer}")
            if resp.status_code not in (204, 404):
                LOG.warning(
                    f"Failed to delete allocations for consumer {consumer}"
                )
            else:
                LOG.info(f"Deleted allocations for consumer {consumer}")
