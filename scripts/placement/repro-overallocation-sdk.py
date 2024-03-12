import concurrent.futures
import sys
import uuid

import openstack

"""
Reproduction script for race to consume the last inventory piece
https://bugs.launchpad.net/placement/+bug/2039560
using pure placement API interactions
"""

test_resource_class = "CUSTOM_CONCURRENCY_TEST"
test_resource_provider_name = "CONCURRENCY-TEST"


def setup(client):
    if test_resource_class not in [r.name for r in client.resource_classes()]:
        client.create_resource_class(name=test_resource_class)
    rp = client.create_resource_provider(name=test_resource_provider_name)
    client.create_resource_provider_inventory(
        rp, test_resource_class,
        total=1, min_unit=1, max_unit=1, allocation_ratio=1.0)
    candidates = client.get(
        f"/allocation_candidates?resources={test_resource_class}:1").json()
    allocation_request = candidates["allocation_requests"][0]["allocations"]
    user_id = client.get_user_id()
    project_id = client.get_project_id()
    allocation = {
        "consumer_generation": None,
        "consumer_type": "CONCURRENCY_TEST",
        "project_id": project_id,
        "user_id": user_id,
        "allocations": allocation_request
    }
    return rp.id, allocation


def make_allocation(client, allocation):
    consumer_id = str(uuid.uuid4())
    res = client.post("/allocations", json={consumer_id: allocation})
    if res.status_code == 204:
        return consumer_id


def delete_allocation(client, consumer):
    a_res = client.get(f"/allocations/{consumer}").json()
    a_res["allocations"] = {}
    res = client.post("/allocations", json={consumer: a_res})
    if res.status_code != 204:
        return False
    return True


def cleanup(client, rp_id):
    client.delete_resource_provider(rp_id)
    client.delete_resource_class(test_resource_class)


def main(count=2):
    cloud = openstack.connect()
    client = cloud.placement
    client.default_microversion = "1.39"  # Yoga+
    rp_id, allocation = setup(client)
    try:
        with concurrent.futures.ThreadPoolExecutor() as executor:
            consumers = list(
                executor.map(
                    make_allocation,
                    [client] * count,
                    [allocation] * count,
                )
            )
        if len(list(filter(None, consumers))) != 1:
            input(f"Caught it! RP ID is: {rp_id}")
        for consumer in consumers:
            delete_allocation(client, consumer)
    finally:
        cleanup(client, rp_id)


if __name__ == "__main__":
    repeats = 1
    if len(sys.argv) > 1:
        repeats = int(sys.argv[1])
    for _i in range(repeats):
        main()
