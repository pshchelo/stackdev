#!/usr/bin/env python3
"""
Compare nova hypervisor stats with their corresponding
placement resource provider inventories:
    - number of vms vs number of allocations
    - total and used vcpu
    - total and used memory
    - total and used disk
"""
import openstack
cloud = openstack.connect()

hvs = list(cloud.compute.hypervisors(details=True))
rps = list(cloud.placement.resource_providers())

for hv in sorted(hvs, key=lambda x: x.name):
    print(f"checking hypervisor {hv.name}")
    rp = [r for r in rps if r.name == hv.name][0]
    rp_invs = cloud.placement.get(
        f"/resource_providers/{rp.id}/inventories"
    ).json()["inventories"]
    rp_usages = cloud.placement.get(
        f"/resource_providers/{rp.id}/usages"
    ).json()["usages"]
    rp_allocations = cloud.placement.get(
        f"/resource_providers/{rp.id}/allocations"
    ).json()["allocations"]

    # compare instance count
    if hv.running_vms != len(rp_allocations):
        print(f"hv {hv.name} and rp {rp.id} differ in VM count - "
              f"{hv.running_vms} != {len(rp_allocations)}")

    # compare vcpu
    if hv.vcpus != rp_invs["VCPU"]["total"]:
        print(f"hv {hv.name} and rp {rp.id} differ in VCPU total - "
              f"{hv.vcpus} != {rp_invs['VCPU']['total']}")
    if hv.vcpus_used != rp_usages["VCPU"]:
        print(f"hv {hv.name} and rp {rp.id} differ in VCPU usage - "
              f"{hv.vcpus_used} != {rp_usages['VCPU']}")

    # compare mem
    if hv.memory_size != rp_invs["MEMORY_MB"]["total"]:
        print(f"hv {hv.name} and rp {rp.id} differ in MEMORY_MB total- "
              f"{hv.memory_size} != {rp_invs['MEMORY_MB']['total']}")
    if hv.memory_used != rp_usages["MEMORY_MB"]:
        print(f"hv {hv.name} and rp {rp.id} differ in MEMORY_MB usage - "
              f"{hv.memory_used} != {rp_usages['MEMORY_MB']}")

    # compare disk
    if hv.local_disk_size != rp_invs["DISK_GB"]["total"]:
        print(f"hv {hv.name} and rp {rp.id} differ in DISK_GB total - "
              f"{hv.local_disk_size} != {rp_invs['DISK_GB']['total']}")
    if hv.local_disk_used != rp_usages["DISK_GB"]:
        print(f"hv {hv.name} and rp {rp.id} differ in DISK_GB usage - "
              f"{hv.local_disk_used} != {rp_usages['DISK_GB']}")
