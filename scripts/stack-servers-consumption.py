#!/usr/bin/env python3
import sys
import openstack

cloud = openstack.connect()
heat = cloud.orchestration
nova = cloud.compute


def get_servers_in_stack(stack):
    server_resources = heat.get(
        f"/stacks/{stack.name}/{stack.id}/resources",
        params={"type": "OS::Nova::Server", "nested_depth": "999"}
    ).json()
    return list(r["physical_resource_id"]
                for r in server_resources["resources"])


def servers_consumption(servers):
    ram = 0
    disk = 0
    vcpus = 0
    ephemeral = 0
    swap = 0
    for server_id in servers:
        try:
            server = nova.get_server(server_id)
        except openstack.exceptions.ResourceNotFound:
            print(f"Server {server_id} not found, deleted manually?")
            continue
        vcpus += server.flavor["vcpus"]  # number
        ram += server.flavor["ram"]  # Megabytes
        disk += server.flavor["disk"]  # Gigabytes
        ephemeral += server.flavor["ephemeral"]  # Gigabytes
        swap += server.flavor["swap"]  # Gigabytes
    return {
        "vcpus": {"value": vcpus,
                  "units": ""},
        "ram": {"value": ram / 1024,
                "units": "GB"},
        "disk": {"value": disk,
                 "units": "GB"},
        "ephemeral": {"value": ephemeral,
                      "units": "GB"},
        "swap": {"value": swap,
                 "units": "GB"},
    }


if __name__ == "__main__":
    stack_name = sys.argv[1]
    stack = heat.find_stack(stack_name)
    if not stack:
        sys.exit(f"Stack {stack_name} not found.")
    servers = get_servers_in_stack(stack)
    if not servers:
        print("Stack {stack_name} defines no servers")
        sys.exit(0)
    print(f"{len(servers)} servers consume:")
    consumed = servers_consumption(servers)
    for k,v in consumed.items():
        print(f"{k}: {v['value']} {v['units']}")
