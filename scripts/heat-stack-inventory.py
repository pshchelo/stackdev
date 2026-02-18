"""
Generate YAML with nodes info usable as Ansible inventory (default)
or with Mirantis si-tests harness. Output is printed to stdout.
"""
import argparse
import openstack
import os
import sys
import yaml


def get_server_fips_from_stack(
    cloud: openstack.connection.Connection,
    stack_name: str, ip_version: int = 4
) -> dict[str: dict[str, str]]:
    stack = cloud.orchestration.find_stack(stack_name)
    server_resources = cloud.orchestration.get(
        f"/stacks/{stack.name}/{stack.id}/resources",
        params={"type": "OS::Nova::Server", "nested_depth": "999"}
    ).json()
    servers = {}
    for r in server_resources["resources"]:
        server_id = r["physical_resource_id"]
        server = cloud.compute.find_server(server_id, ignore_missing=True)
        if not server:
            print(f"WARNING: server {server_id} not found")
            continue
        server_fip = None
        for net_addrs in server.addresses.values():
            for addr in net_addrs:
                if (
                    addr["OS-EXT-IPS:type"] == "floating" and
                    addr['version'] == ip_version
                ):
                        server_fip = addr["addr"]
                        break
            if server_fip:
                servers[server.hostname] = server_fip
                break
        else:
            print(f"WARNING: no FIP with IPv{ip_version} found "
                  f"for server {server_id}")
    return {stack_name: servers}


def format_ansible(
    servers: dict[str: dict[str: str]],
    user: str, key: str, port: int = 22, strict: bool = True
) -> dict[str: dict]:
    inventory = {}
    for group, srvs in servers.items():
        ssh_opts = []
        vars = {
            "ansible_user": user,
            "ansible_ssh_private_key_file": key,
            "ansible_port": port,
        }
        if not strict:
            ssh_opts.extend([
                "-o StrictHostKeyChecking=no",
                "-o UserKnownHostsFile=/dev/null",
            ])
        if ssh_opts:
            vars["ansible_ssh_common_args"] = " ".join(ssh_opts)
        hosts = {name: {"ansible_host": ip} for name, ip in srvs.items()}
        inventory[group] = {"vars": vars, "hosts": hosts}
    return inventory


def format_sitests(
    servers: dict[str: dict[str: str]],
    user: str, key: str, port: int = 22, strict: bool = True
) -> dict[str: dict]:
    inventory = {}
    for server, address in list(servers.values())[0].items():
        inventory[server] = {"ip": {"address": address}}
        inventory[server]["ssh"] = {
                "username": user,
                "private_key_path": key,
                "port": port,
        }
    return inventory


def main():
    this_module = sys.modules[__name__]
    parser = argparse.ArgumentParser(
        prog=os.path.basename(sys.argv[0]),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description=this_module.__doc__,
    )
    parser.add_argument("stack", help="Name or ID of the stack to parse")
    parser.add_argument("--user", default="ubuntu", help="SSH user to use")
    parser.add_argument("--key", default="~/.ssh/aio_rsa",
                        help="path to SSH private key")
    parser.add_argument("--port", default=22, help="SSH port to use")
    parser.add_argument("--ip-version", type=int, choices=[4, 6], default=4,
                        help="IP version of address to use")
    parser.add_argument("--format",
                        choices=["ansible", "sitests"],
                        default="ansible",
                        help="Format of inventory to generate")
    parser.add_argument("--strict", action="store_true",
                        help="Enable strict host key check")
    cloud = openstack.connect(options=parser)
    args = parser.parse_args()
    formatter = getattr(this_module, f"format_{args.format}", None)
    if not formatter:
        raise NotImplementedError(f"No formatter for {args.format} found.")
    servers = get_server_fips_from_stack(
        cloud, args.stack, ip_version=args.ip_version)
    inventory = formatter(
        servers, args.user, args.key, port=args.port, strict=args.strict)
    print(yaml.dump(inventory))


if __name__ == "__main__":
    main()
