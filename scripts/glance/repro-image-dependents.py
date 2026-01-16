#!/usr/bin/env python3
import logging
import os
import random

import openstack

"""
Check image is independent from snapshots.

Same as tempest.api.image.v2.test_images_dependency.ImageDependencyTests
tests but w/o tempest:
- create image
- create volume from image - optional
- create server from image or from volume
- make snapshot of the server (snapshots local disk or volume to image)
- delete image - main point to check
- delete server
- delete snapshot
"""

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)


def str_to_bool(val: str) -> bool:
    err_msg =  f"Can't convert value {val} to boolean"
    try:
        if val.lower() in ("1", "true", "t", "yes", "y"):
            return True
        elif val.lower() in ("0", "false", "f", "no", "n"):
            return False
    except AttributeError:
        raise ValueError(err_msg)
    raise ValueError(err_msg)


IMAGE_SIZE_BYTES = 1024
PREFIX = "test"
BOOT_FROM_VOLUME = str_to_bool(os.getenv("BOOT_FROM_VOLUME", "0"))

cloud = openstack.connect()

random_blob = b''.join(
    [bytes((random.randint(0, 255),)) for i in range(IMAGE_SIZE_BYTES)]
)
image = cloud.image.create_image(
    f"{PREFIX}-image",
    data=random_blob,
    container_format="bare",
    disk_format="raw",
    wait=True,
)
log.info("Created image")
server_kwargs = dict(
    image=image,
    flavor="m1.nano",
    auto_ip=False,
    wait=True,
)
if BOOT_FROM_VOLUME:
    server_kwargs.update(dict(boot_from_volume=True, volume_size=1))
server = cloud.create_server(f"{PREFIX}-server", **server_kwargs)
log.info("Created server")
snapshot = cloud.compute.create_server_image(
    server,
    f"{PREFIX}-snapshot",
    wait=True
)
log.info("Created server snapshot")
cloud.delete_image(image.id, wait=True)
log.info("Deleted image")
cloud.delete_server(server.id, wait=True)
log.info("Deleted server")
cloud.delete_image(snapshot.id, wait=True)
log.info("Deleted snapshot")
