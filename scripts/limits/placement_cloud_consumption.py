#!/usr/bin/env python3
"""
Calculate total cloud resource usage from data in the Placement service.
"""
import sys
import openstack
cloud = openstack.connect()
placement = cloud.placement
placement.default_microversion = "1.39"
query={}
if len(sys.argv) > 1:
    query["required"] = sys.argv[1]
total = {}
for rp in placement.resource_providers(**query):
    usage = placement.get(
        f"/resource_providers/{rp.id}/usages"
    ).json()["usages"]
    for res, count in usage.items():
        total[res] = total.get(res, 0) + count
for res, count in total.items():
    print(f"{res}: {count}")
