#!/usr/bin/env python3
"""
Compare servers in nova with consumers in placement and find discrepancies
"""
import logging
import openstack
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
LOG = logging.getLogger("servers-vs-consumers")
LOG.setLevel(logging.DEBUG)
cloud = openstack.connect()
fails = []
for server in cloud.compute.servers(all_projects=True):
    LOG.debug(f"Checking server {server.id}")
    allocations = cloud.placement.get(
        f"/allocations/{server.id}").json()["allocations"]
    if not allocations:
        # server might've been deleted already, find it again
        if cloud.compute.find_server(
            server.id, all_projects=True, ignore_missing=True
        ):
            msg = f"has status {server.status} and no allocations in placement"
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        continue
    for rp_id, alloc in allocations.items():
        rp = cloud.placement.get_resource_provider(rp_id)
        if rp.name != server.hypervisor_hostname:
            msg = (f"is on {server.hypervisor_hostname} in nova "
                   f"but on {rp.name} in placement")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        alloc_vcpu = alloc["resources"].get("VCPU", 0)
        if alloc_vcpu != server.flavor.vcpus:
            msg = (f"VCPU: flavor={server.flavor.vcpus}, "
                   f"placement={alloc_vcpu}")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        alloc_mem = alloc["resources"].get("MEMORY_MB", 0)
        if alloc_mem != server.flavor.ram:
            msg = (f"MEMORY_MB: flavor={server.flavor.ram}, "
                   f"placement={alloc_mem}")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        alloc_disk = alloc["resources"].get("DISK_GB", 0)
        if alloc_disk != (server.flavor.disk + server.flavor.swap +
                          server.flavor.ephemeral):
            msg = (f"DISK_GB: "
                   f"flavor={server.flavor.disk}d+{server.flavor.swap}s+"
                   f"{server.flavor.ephemeral}e, "
                   f"placement={alloc_disk}t")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
if fails:
    print(fails)
