import argparse
import random
import time

from loguru import logger as LOG
import openstack

IMAGE = "Cirros-6.0"
FLAVOR = "m1.nano"


class VolumeStatusTimeout(Exception):
    pass


class VolumeSwapRepro():

    def __init__(self, cloud, timeout=600, poll=5, debug=False):
        self.timeout = timeout
        self.poll = poll
        openstack.enable_logging(http_debug=debug)
        self.cloud = openstack.connect(cloud)
        self.server = None
        self.vol1 = None
        self.vol2 = None
        self.server_name = f"VolumeSwapRepro-{random.choice(range(10000))}"

    def setup(
        self,
        flavor: str = FLAVOR,
        image: str = IMAGE,
        size: int = 1
    ) -> None:
        LOG.info("Creating resources")
        LOG.debug("Creating volume vol1")
        self.vol1 = self.cloud.create_volume(
            size=size, timeout=self.timeout, wait=True)
        LOG.info("Created volume {}", self.vol1.id)
        LOG.debug("Creating volume vol2")
        self.vol2 = self.cloud.create_volume(
            size=size, timeout=self.timeout, wait=True)
        LOG.info("Created volume {}", self.vol2.id)
        LOG.debug("Creating server")
        self.server = self.cloud.create_server(
            self.server_name, image=image, flavor=flavor,
            auto_ip=False, wait=True,
        )
        LOG.info("Created server {}", self.server.id)
        LOG.debug("Attaching volume {} to server {}", self.vol1.id, self.server.id)
        self.cloud.attach_volume(
            self.server, self.vol1, wait=True, timeout=self.timeout)

    def test_swap_volume(self) -> None:
        LOG.info("Swapping volumes {} -> {}", self.vol1.id, self.vol2.id)
        self.swap_volume(self.vol1, self.vol2)
        LOG.debug("Waiting for volume statuses")
        self.wait_for_volume(self.vol1, "available")
        self.wait_for_volume(self.vol2, "in-use")
        LOG.info("Swapping volumes back {} -> {}", self.vol2.id, self.vol1.id)
        self.swap_volume(self.vol2, self.vol1)
        LOG.debug("Waiting for volume statuses")
        self.wait_for_volume(self.vol1, "in-use")
        self.wait_for_volume(self.vol2, "available")

    def cleanup(self) -> None:
        if self.server:
            LOG.info("Deleting server {}", self.server.id)
            self.cloud.delete_server(
                self.server.id, timeout=self.timeout, wait=True)
        for vol in (self.vol1, self.vol2):
            if vol:
                LOG.info("Deleting volume {}", vol.id)
                self.cloud.delete_volume(
                    vol.id, timeout=self.timeout, wait=True)

    def swap_volume(self, old_volume, new_volume) -> None:
        self.server = self.cloud.compute.get_server(self.server)
        assert self.server is not None, \
        f"Failed to find server {self.server.id}"
        attached_volumes = [vol.id for vol in self.server.attached_volumes]
        assert old_volume.id in attached_volumes, \
        f"volume {old_volume.id} is not attached to server {self.server.id}"
        assert new_volume.id not in attached_volumes, \
        f"volume {new_volume.id} is already attached to server {self.server.id}"
        self.cloud.compute.put(
            f"/servers/{self.server.id}/os-volume_attachments/{old_volume.id}",
            json={
                "volumeAttachment": {
                    "volumeId": new_volume.id
                }
            },
            raise_exc=True
        )

    def wait_for_volume(self, volume, status: str) -> None:
        start = time.time()
        while time.time() - start <= self.timeout:
            if self.cloud.get_volume(volume.id).status == status:
                LOG.info("Volume {} went to status {}", volume.id, status)
                return
            time.sleep(self.poll)
        msg = (f"Volume {volume.id} failed to become {status} "
               f"within {self.timeout} s.")
        LOG.error(msg)
        raise VolumeStatusTimeout(msg)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="swap-volume-repro")
    parser.add_argument("--timeout", type=int, default=600,
                        help="timeout used by all the waiters, in seconds")
    parser.add_argument("--poll", type=int, default=5,
                       help="polling interval of waiters, in seconds")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--os-cloud", default=None)
    args = parser.parse_args()
    return args


def main() -> None:
    args = parse_args()
    repro = VolumeSwapRepro(
        args.os_cloud, timeout=args.timeout, poll=args.poll, debug=args.debug)
    try:
        repro.setup()
        repro.test_swap_volume()
    finally:
        repro.cleanup()

if __name__ == "__main__":
    main()
