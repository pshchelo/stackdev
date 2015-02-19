#!/usr/bin/env python
from __future__ import print_function

import os
import sys

from neutronclient.v2_0 import client


neutron = client.Client(auth_url=os.environ['OS_AUTH_URL'],
                        username=os.environ['OS_USERNAME'],
                        password=os.environ['OS_PASSWORD'],
                        tenant_name=os.environ['OS_TENANT_NAME'])

all_sec_groups = neutron.list_security_groups()['security_groups']

for sg in all_sec_groups:
    if sg['name'] == 'default':
        default_sg = sg
        break
else:
    print ('Default security group not found')
    sys.exit(1)


for rule in default_sg['security_group_rules']:
    neutron.delete_security_group_rule(rule['id'])

new_rules = [
    {'direction': 'ingress',
     'ethertype': 'IPv4',
     'protocol': 'tcp',
     'remote_ip_prefix': '0.0.0.0/0',
     'port_range_min': 1,
     'port_range_max': 1024
     },

    {'direction': 'egress',
     'ethertype': 'IPv4',
     'protocol': 'tcp',
     'remote_ip_prefix': '0.0.0.0/0',
     'port_range_min': 1,
     'port_range_max': 1024
     },
    {'direction': 'ingress',
     'ethertype': 'IPv4',
     'protocol': 'icmp',
     'remote_ip_prefix': '0.0.0.0/0',
     'port_range_min': None,
     'port_range_max': None
     },
    {'direction': 'egress',
     'ethertype': 'IPv4',
     'protocol': 'icmp',
     'remote_ip_prefix': '0.0.0.0/0',
     'port_range_min': None,
     'port_range_max': None
     },
]

for rule in new_rules:
    rule['security_group_id'] = default_sg['id']
    neutron.create_security_group_rule({'security_group_rule': rule})
