import pprint
import sys
import openstack
cloud = openstack.connect()

total = {"total": {}, "used": {}, "free": {}}

cloud.placement.default_microversion = 1.22
query = sys.argv[1] if len(sys.argv) > 1 else "!COMPUTE_STATUS_DISABLED"
rprovs = cloud.placement.resource_providers(required=query)

for rp in rprovs:
    inv = cloud.placement.get(
        f"/resource_providers/{rp.id}/inventories").json()
    usage = cloud.placement.get(f"/resource_providers/{rp.id}/usages").json()
    for k, used in usage['usages'].items():
        for m in total:
            total[m].setdefault(k, 0)
        i = inv['inventories'][k]
        rp_total = (i['total'] - i['reserved']) * i['allocation_ratio']
        total["used"][k] += used
        total["total"][k] += rp_total
        total["free"][k] += rp_total - used
pprint.pprint(total)
