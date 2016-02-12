#!/usr/bin/env python

import csv
import os
import SimpleHTTPServer
import SocketServer

from glanceclient import client
from keystoneauth1 import identity
from keystoneauth1 import session


CSV_FILE = "cmdb.csv"
PORT = 9999

auth_params = {
    'auth_url': os.environ.get('OS_AUTH_URL', 'http://0.0.0.0:5000/v3'),
    'username': os.environ.get('OS_USERNAME', 'admin'),
    'password': os.environ.get('OS_PASSWORD', 'admin'),
    'domain_name': os.environ.get('OS_DOMAIN_NAME', 'Default'),
    'user_domain_name': os.environ.get("OS_USER_DOMAIN_NAME", "Default"),
}

auth = identity.V3Password(**auth_params)
sess = session.Session(auth=auth)
glance = client.Client(version=2, session=sess)
images = glance.images.list()

deploy_kernel = None
deploy_ramdisk = None

for image in images:
    if image.name.startswith("ir-deploy"):
        if image.name.endswith('.kernel'):
            deploy_kernel = image.id
        elif image.name.endswith('.initramfs'):
            deploy_ramdisk = image.id
        if deploy_kernel and deploy_ramdisk:
            break
    else:
        continue

macs_file = "/opt/stack/data/ironic/ironic_macs.csv"
macs = []
with open(macs_file) as f:
    reader = csv.reader(f)
    macs = list(reader)

cmdb_common = (
    ("mac", None),
    ("/driver_info/ssh_port", 22),
    ("/driver_info/ssh_address", "192.168.100.126"),
    ("/driver_info/ssh_virt_type", "virsh"),
    ("/driver_info/ssh_username", "pshchelo"),
    ("/driver_info/ssh_key_filename",
        "/opt/stack/data/ironic/ssh_keys/ironic_key"),
    ("/driver_info/deploy_kernel", deploy_kernel),
    ("/driver_info/deploy_ramdisk", deploy_ramdisk),
)
fields = [item[0] for item in cmdb_common]

cmdb = []
for mac in macs:
    node = dict(cmdb_common)
    node['mac'] = mac[0]
    cmdb.append(node)

with open(CSV_FILE, "w") as out:
    writer = csv.DictWriter(out, fieldnames=fields)
    writer.writeheader()
    for node in cmdb:
        writer.writerow(node)

Handler = SimpleHTTPServer.SimpleHTTPRequestHandler
httpd = SocketServer.TCPServer(("", PORT), Handler)
print("serving at port {}".format(PORT))
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\nShutting down")
    httpd.shutdown()
    os.remove(CSV_FILE)
