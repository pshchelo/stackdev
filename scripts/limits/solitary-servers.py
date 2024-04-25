#!/usr/bin/env python3
import openstack

cloud = openstack.connect()


def get_servers_in_stacks():
    heat = cloud.orchestration
    servers_in_stacks = []
    for stack in heat.stacks():
        server_resources = heat.get(
            f"/stacks/{stack.name}/{stack.id}/resources",
            params={"type": "OS::Nova::Server", "nested_depth": "999"}
        ).json()
        servers_in_stacks.extend(
            [r["physical_resource_id"] for r in server_resources["resources"]])
    return servers_in_stacks


def get_solitary_servers():
    nova = cloud.compute
    servers_in_stacks = get_servers_in_stacks()
    return [s for s in nova.servers() if s.id not in servers_in_stacks]


if __name__ == "__main__":
    for server in sorted(get_solitary_servers(), key=lambda x: x.created_at):
        print(server.id, server.created_at, server.status, server.name)
