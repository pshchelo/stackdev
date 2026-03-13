#!/usr/bin/env python3
# /// script
# dependencies = ["openstacksdk"]
# ///

import csv
import os
import http.server

import openstack


CSV_FILE = "cmdb.csv"
PORT = 9999

cloud = openstack.connect()
images = cloud.list_images()

deploy_kernel = None
deploy_ramdisk = None

for image in images:
    if image.name.startswith("ir-deploy"):
        if image.name.endswith(".kernel"):
            deploy_kernel = image.id
        elif image.name.endswith(".initramfs"):
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
    ("/driver_info/ssh_key_filename", "/opt/stack/data/ironic/ssh_keys/ironic_key"),
    ("/driver_info/deploy_kernel", deploy_kernel),
    ("/driver_info/deploy_ramdisk", deploy_ramdisk),
)
fields = [item[0] for item in cmdb_common]

cmdb = []
for mac in macs:
    node = dict(cmdb_common)
    node["mac"] = mac[0]
    cmdb.append(node)

with open(CSV_FILE, "w") as out:
    writer = csv.DictWriter(out, fieldnames=fields)
    writer.writeheader()
    for node in cmdb:
        writer.writerow(node)

httpd = http.server.ThreadingHTTPServer(
    ("", PORT),
    http.server.BaseHTTPRequestHandler,
)
print("serving at port {}".format(PORT))
try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\nShutting down")
    httpd.shutdown()
    os.remove(CSV_FILE)
