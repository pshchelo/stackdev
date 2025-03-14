#!/usr/bin/env python3
import argparse

import openstack

parser = argparse.ArgumentParser(
    prog="project-resources",
    description="Get available RAM and vCPU for an OpenStack project"
)
parser.add_argument("--os-cloud",
                    metavar="<CLOUD>",
                    default=None,
                    help="Name of the entry in clouds.yaml config, defaults "
                         "to OC_CLOUD env var.")
args = parser.parse_args()

cloud = openstack.connect(cloud=args.os_cloud)

nova_limits = cloud.compute.get_limits()
available_cores = (
    nova_limits.absolute.total_cores - nova_limits.absolute.total_cores_used
)
available_ram = (
    nova_limits.absolute.total_ram - nova_limits.absolute.total_ram_used
)

print(f"Available Cores: {available_cores}")
print(f"Available RAM:   {available_ram // 1024} GB")
