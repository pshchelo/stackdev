#! /usr/bin/env python

import glanceclient
import keystoneclient
import neutronclient
import novaclient

ADMIN_CREDS_PATH = '/opt/stack/devstack/accrc/admin/admin'
DEMO_CREDS_PATH = '/opt/stack/devstack/accrc/demo/demo'


def read_creds(path):
    creds = {}
    return creds


def admin_creds():
    return read_creds(ADMIN_CREDS_PATH)


def demo_creds():
    return read_creds(DEMO_CREDS_PATH)


def is_neutron():
    creds = demo_creds()
    client = keystoneclient.client(**creds)
    client.catalog()


def rename_image(old_regex, new):
    creds = admin_creds()
    client = glanceclient.Client('2', **creds)
    image = client.images.get(old_regex)
    image.update(name=new, description=image.name)


def fix_default_secgroup_neutron():
    creds = demo_creds()
    neutronclient.Client(**creds)


def fix_default_secgroup_nova():
    creds = demo_creds()
    novaclient.Client(**creds)


def add_google_dns_neutron():
    creds = demo_creds()
    client = neutronclient.Client(**creds)
    subnet = client.subnets.get()
    subnet.update(dns_servers='8.8.8.8')


def add_google_dns_nova():
    creds = demo_creds()
    novaclient.Client(**creds)


def create_keypair():
    creds = demo_creds()
    client = novaclient.Client(**creds)
    keypair = client.keypairs.create(name=creds['user'])
    private_key_name = '%s.pem' % creds['user']
    with open(private_key_name, 'w') as f:
        f.write(keypair.private)

if __name__ == '__main__':
    pass
