import openstack


def gather_info():
    cloud = openstack.connect()
    cloud.placement.default_microversion = 1.1  # for aggregate support
    n_aggs = list(cloud.compute.aggregates())
    res = []
    for node in cloud.baremetal.nodes():
        rp = cloud.placement.find_resource_provider(node.id)
        pl_aggs = cloud.placement.get(
            f"/resource_providers/{rp.id}/aggregates").json()['aggregates']
        aggs = [a.name for a in n_aggs if a.uuid in pl_aggs]
        res.append(dict(node=node.id, rp=rp.id, ag_ids=pl_aggs, ag_names=aggs))
    return res


def output_info(res):
    header = "\t".join(
        (
            "Node" + "\t"*4,
            "Resource Provider" + "\t"*2,
            "Placement Aggregates" + "\t"*2,
            "Nova Aggregates",
        ))
    print(header)
    for item in res:
        print("\t".join((
            item["node"],
            item["rp"],
            ",".join(item["ag_ids"]),
            ",".join(item["ag_names"]),
        )))


if __name__ == "__main__":
    output_info(gather_info())
