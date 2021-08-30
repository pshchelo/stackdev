#!/usr/bin/env python3
import openstack

cloud = openstack.connect()

nova_limits = cloud.compute.get_limits()
available_cores = nova_limits.absolute.total_cores - nova_limits.absolute.total_cores_used
available_ram = nova_limits.absolute.total_ram - nova_limits.absolute.total_ram_used

print(f"Available Cores: {available_cores}")
print(f"Available RAM:   {available_ram // 1024} GB")
