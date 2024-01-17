#!/usr/bin/env python3
"""
Calculate total cloud resource usage from data in the Placement service.
"""
import openstack
cloud = openstack.connect()
total = {}
for rp in cloud.placement.resource_providers():
    usage = cloud.placement.get(
        f"/resource_providers/{rp.id}/usages"
    ).json()["usages"]
    for res, count in usage.items():
        total[res] = total.get(res, 0) + count
for res, count in total.items():
    print(f"{res}: {count}")
