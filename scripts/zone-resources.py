import openstack, sys, pprint

zone = sys.argv[1]

cloud = openstack.connect()

hosts = set()

hosts.update(*[a.hosts for a in cloud.compute.aggregates() if a.availability_zone == zone])

hypervisors = [h for h in cloud.compute.hypervisors() if h.name.split('.')[0] in hosts]

rprovs = [cloud.placement.find_resource_provider(name_or_id=h.name) for h in hypervisors]

total = {"total": {}, "used": {}, "free": {}}

for rp in rprovs:
    inv = cloud.placement.get(f"/resource_providers/{rp.id}/inventories").json()
    usage = cloud.placement.get(f"/resource_providers/{rp.id}/usages").json()
    for k,used in usage['usages'].items():
        for m in total:
            total[m].setdefault(k, 0)
        i = inv['inventories'][k]
        rp_total = (i['total'] - i['reserved']) * i['allocation_ratio']
        total["used"][k] += used
        total["total"][k] += rp_total
        total["free"][k] += rp_total - used
pprint.pprint(total)
