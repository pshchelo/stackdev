#!/usr/bin/env python3
"""
Compare servers in nova with consumers in placement and find discrepancies
"""
import argparse
import json
import logging
import openstack
parser = argparse.ArgumentParser()
parser.add_argument("-v", "--verbose", action="store_true")
args = parser.parse_args()
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
LOG = logging.getLogger("servers-vs-consumers")
if args.verbose:
    LOG.setLevel(logging.DEBUG)
cloud = openstack.connect()

compute_api_version = [
    v["max_microversion"] for v in cloud.compute.get_all_version_data()[
        cloud.compute.region_name
    ]['public']['compute']
    if v['status'] == 'CURRENT'
][0].split(".")

# For Queens (2.60) and older, count BFV disk root to placement too
# TODO: verify that Queens is enough
# for sure needed for Queens and not needed for Yoga+
count_disk_for_bfv = compute_api_version <= ["2", "60"]

fails = []
for server in cloud.compute.servers(all_projects=True):
    LOG.debug(f"Checking server {server.id}")
    allocations = cloud.placement.get(
        f"/allocations/{server.id}").json()["allocations"]
    if not allocations:
        # server might've been deleted already, find it again
        server = cloud.compute.find_server(
            server.id, all_projects=True, ignore_missing=True
        )
        # ignore servers that are not assigned a compute,
        # it is ok for them not to have allocations
        # (like failed to schedule)
        if server and server.compute_host:
            msg = (
                f"has status {server.status} "
                f"and host {server.compute_host} "
                f"but no allocations in placement"
            )
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        continue
    for rp_id, alloc in allocations.items():
        rp = cloud.placement.get_resource_provider(rp_id)
        alloc_vcpu = alloc["resources"].get("VCPU", 0)
        alloc_mem = alloc["resources"].get("MEMORY_MB", 0)
        alloc_disk = alloc["resources"].get("DISK_GB", 0)
        if alloc_vcpu + alloc_mem + alloc_disk == 0:
            LOG.debug(f"server {server.id} appears to be baremetal one as "
                      f"it does not allocate neither cpu, nor ram, nor disk.")
            continue
        if server.hypervisor_hostname is None:
            msg = (f"has status {server.status}, is not assigned to host in "
                   f"nova, but is on {rp.name} in placement")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        elif rp.name != server.hypervisor_hostname:
            msg = (f"is on {server.hypervisor_hostname} in nova "
                   f"but on {rp.name} in placement")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        if alloc_vcpu != server.flavor.vcpus:
            msg = (f"VCPU: flavor={server.flavor.vcpus}, "
                   f"placement={alloc_vcpu}")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
        if alloc_mem != server.flavor.ram:
            msg = (f"MEMORY_MB: flavor={server.flavor.ram}, "
                   f"placement={alloc_mem}")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})

        expected_alloc_disk = (
            server.flavor.swap +
            server.flavor.ephemeral
        )
        if server.image.id is not None or count_disk_for_bfv is True:
            expected_alloc_disk += server.flavor.disk
        if alloc_disk != expected_alloc_disk:
            msg = (f"DISK_GB: "
                   f"flavor={expected_alloc_disk}, "
                   f"placement={alloc_disk}")
            LOG.warning(f"Server {server.id} {msg}")
            fails.append({"server_id": server.id, "reason": msg})
if fails:
    print(json.dumps(fails, indent=4))
