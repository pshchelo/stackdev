#!/usr/bin/env python3
import openstack


def list_placement_aggregates(cloud):
    for rp in cloud.placement.resource_providers():
        rp_aggs = cloud.placement.get(
            f"/resource_providers/{rp.id}/aggregates"
        ).json()
        print(rp.id, " ".join(rp_aggs["aggregates"]))


if __name__ == "__main__":
    cloud = openstack.connect()
    cloud.placement.default_microversion = "1.39"
    list_placement_aggregates(cloud)
