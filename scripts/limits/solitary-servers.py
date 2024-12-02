#!/usr/bin/env python3
import argparse

import openstack


def setup_cli():
    parser = argparse.ArgumentParser(
        prog="solitary-servers",
        description="Find Nova servers that are not part of any Heat Stack"
    )
    parser.add_argument(
        "--os-cloud",
        dest="cloud_name",
        help="Cloud to use (from clouds.yaml). Default is from OS_CLOUD env var."
    )
    return parser.parse_args()


def get_servers_in_stacks(cloud):
    servers_in_stacks = []
    for stack in cloud.orchestration.stacks():
        server_resources = cloud.orchestration.get(
            f"/stacks/{stack.name}/{stack.id}/resources",
            params={"type": "OS::Nova::Server", "nested_depth": "999"}
        ).json()
        servers_in_stacks.extend(
            [r["physical_resource_id"] for r in server_resources["resources"]])
    return servers_in_stacks


def get_solitary_servers(cloud):
    servers_in_stacks = get_servers_in_stacks(cloud)
    return [
        s for s in cloud.compute.servers()
        if s.id not in servers_in_stacks
    ]


def print_servers_table(servers):
    if not servers:
        print("No solitary servers found")
        return
    print(
        "Instance-Id",
        "Created-At",
        "Status",
        "Task-State",
        "VCPU",
        "RAM",
        "Total-Disk",
        "Name",
    )
    for server in sorted(servers, key=lambda x: x.created_at):
        print(
            server.id,
            server.created_at,
            server.status,
            server.task_state,
            server.flavor.vcpus,
            server.flavor.ram,
            server.flavor.disk + server.flavor.swap + server.flavor.ephemeral,
            server.name,
        )


if __name__ == "__main__":
    args = setup_cli()
    cloud = openstack.connect(cloud=args.cloud_name)
    servers = get_solitary_servers(cloud)
    print_servers_table(servers)
