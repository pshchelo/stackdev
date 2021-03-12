import sys
import openstack

cloud = openstack.connect()
heat = cloud.orchestration
nova = cloud.compute


def get_servers_in_stack(stack_name):
    stack = heat.find_stack(stack_name)
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
        server = nova.get_server(server_id)
        vcpus += server.flavor["vcpus"]
        ram += server.flavor["ram"]
        disk += server.flavor["disk"]
        ephemeral += server.flavor["ephemeral"]
        swap += server.flavor["swap"]
    return {"vcpus": vcpus, "ram": ram, "disk": disk, "swap": swap,
            "ephemeral": ephemeral}


if __name__ == "__main__":
    stack_name = sys.argv[1]
    servers = get_servers_in_stack(stack_name)
    print(f"Number of servers: {len(servers)}")
    print(servers_consumption(servers))
