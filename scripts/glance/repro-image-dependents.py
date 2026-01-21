#!/usr/bin/env python3
import argparse
import logging
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
PROG = "repro-image_dependents"
IMAGE_SIZE_BYTES = 1024

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
log = logging.getLogger(PROG)


def str_to_bool(val: str) -> bool:
    err_msg = f"Can't convert value {val} to boolean"
    try:
        if val.lower() in ("1", "true", "t", "yes", "y"):
            return True
        elif val.lower() in ("0", "false", "f", "no", "n"):
            return False
    except AttributeError:
        raise ValueError(err_msg)
    raise ValueError(err_msg)


parser = argparse.ArgumentParser(
    prog=PROG,
    description=__doc__,
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
)

parser.add_argument(
    "--bfv",
    action="store_true",
    default=False,
    help="Create instance from volume created from image",
)
parser.add_argument(
    "-f", "--flavor", default="m1.nano", help="Flavor for the instance"
)
parser.add_argument(
    "--network",
    help="network where to create server, will try to be autodetected",
)
parser.add_argument(
    "--prefix", default="test", help="name prefix for created resources"
)
parser.add_argument(
    "--create-only",
    action="store_true",
    default=False,
    help="No cleanup, leave created resources intact",
)
parser.add_argument(
    "--debug", action="store_true", default=False, help="Log more"
)
cloud = openstack.connect(options=parser)
args = parser.parse_args()

if args.debug:
    log.setLevel(logging.DEBUG)

image = None
server = None
snapshot = None

try:
    random_blob = b"".join(
        [bytes((random.randint(0, 255),)) for i in range(IMAGE_SIZE_BYTES)]
    )
    log.debug("Creating image..")
    image = cloud.image.create_image(
        f"{args.prefix}-image",
        data=random_blob,
        container_format="bare",
        disk_format="raw",
        wait=True,
    )
    log.info("Created image")
    server_kwargs = dict(
        image=image,
        flavor=args.flavor,
        auto_ip=False,
        wait=True,
    )
    if args.network:
        server_kwargs.update(dict(network=args.network))
    if args.bfv:
        server_kwargs.update(dict(boot_from_volume=True, volume_size=1))
    server = cloud.create_server(f"{args.prefix}-server", **server_kwargs)

    server = cloud.compute.create_server(
    )

    log.info("Created server")
    snapshot = cloud.compute.create_server_image(
        server, f"{args.prefix}-snapshot", wait=True
    )
    log.info("Created server snapshot")
finally:
    if not args.create_only:
        if image:
            cloud.delete_image(image.id, wait=True)
            log.info("Deleted image")
        if server:
            cloud.delete_server(server.id, wait=True)
            log.info("Deleted server")
        if snapshot:
            cloud.delete_image(snapshot.id, wait=True)
            log.info("Deleted snapshot")
