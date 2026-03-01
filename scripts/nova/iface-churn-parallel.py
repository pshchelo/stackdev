#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "futurist",
#   "libvirt-python",
# ]
# ///
"""Check massive parallel attach/detach of VM interfaces w/o nova"""
import argparse
import logging
import random
import string
import subprocess
import sys
import time
from xml.etree import ElementTree as ET

import futurist
from futurist import waiters
import libvirt

PROGRAM_NAME = "iface-churn-parallel"
LOG = logging.getLogger(PROGRAM_NAME)
# Timeout (seconds) for device to appear/disappear in domain XML
XML_POLL_TIMEOUT = 10
XML_POLL_INTERVAL = 0.1


def _create_tap_interface(index: int) -> None:
    """Create a tap interface on the host. Raises on failure."""
    # tap interface name can be up to 15 characters
    suffix = ''.join(random.choices(string.ascii_letters, k=8))
    tap_name = f'repro{index:02d}{suffix}'
    subprocess.run(
        ["ip", "tuntap", "add", "mode", "tap", tap_name],
        check=True,
        capture_output=True,
    )
    subprocess.run(["ip", "link", "set", tap_name, "up"], check=True, capture_output=True)
    return tap_name


def _delete_tap_interface(tap_name: str) -> None:
    """Delete a tap interface from the host. Raises on failure."""
    subprocess.run(
        ["ip", "tuntap", "del", "mode", "tap", tap_name],
        check=True,
        capture_output=True,
    )


def _build_interface_xml(tap_name: str, alias: str) -> str:
    """Build libvirt interface XML for a pre-created tap device (ethernet, managed='no')."""
    iface = ET.Element("interface", type="ethernet")
    ET.SubElement(iface, "target", dev=tap_name, managed="no")
    ET.SubElement(iface, "model", type="virtio")
    ET.SubElement(iface, "alias", name=alias)
    return ET.tostring(iface).decode()


def _get_interface_xml_by_alias(dom: libvirt.virDomain, alias: str) -> str:
    xml = ET.fromstring(dom.XMLDesc())
    iface = xml.find(f"./devices/interface/alias[@name='{alias}']...")
    if iface is None:
        raise Exception(f"failed to find interface with alias {alias}")
    return ET.tostring(iface).decode()

# TODO(pas-ha): the exact way nova behaves is:
# - delete persistent device xml from persistent config (this is sync)
# - check that device was indeed deleted from persistent config
# - start listening for device deleted or failed event from libvirt for our device
# - delete live device xml from live config (this is async)
# - wait for libvirt event for device deleted
def _wait_for_interface_absent_in_xml(
    conn: libvirt.virConnect,
    domain_name: str,
    tap_name: str,
    timeout: float = XML_POLL_TIMEOUT,
) -> None:
    """Poll domain XML until tap_name is absent. Raises TimeoutError if not satisfied."""
    flags = 0
    persistent_flags = flags | libvirt.VIR_DOMAIN_XML_INACTIVE
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        domain = conn.lookupByName(domain_name)
        live_xml = domain.XMLDesc(flags)
        persistent_xml = domain.XMLDesc(persistent_flags)
        if (tap_name not in live_xml) and (tap_name not in persistent_xml):
            return
        time.sleep(XML_POLL_INTERVAL)
    raise TimeoutError(
        f"Tap {tap_name} did not become absent in domain both live and persistent XML within {timeout}s"
    )


def create_and_attach_interface(
    conn: libvirt.virConnect,
    domain_name: str,
    index: int,
) -> tuple[str, str]:
    domain = conn.lookupByName(domain_name)
    try:
        tap_name = _create_tap_interface(index)
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Failed to create tap interface {tap_name}: {e}") from e
    tap_alias = f"ua-repro-{index:02d}"
    try:
        iface_xml = _build_interface_xml(tap_name, tap_alias)
        flags = libvirt.VIR_DOMAIN_AFFECT_CONFIG | libvirt.VIR_DOMAIN_AFFECT_LIVE
        domain.attachDeviceFlags(iface_xml, flags=flags)
    except libvirt.libvirtError as e:
        try:
            _delete_tap_interface(tap_name)
        except subprocess.CalledProcessError:
            pass
        raise RuntimeError(f"Failed to attach interface to domain: {e}") from e
    return tap_name, tap_alias


def detach_and_delete_interface(conn, domain_name: str, tap_name: str, tap_alias:str) -> None:
    domain = conn.lookupByName(domain_name)
    # need to find iface manually as just using the same XML we generated
    # is not enough to find, needs e.g. mac address.
    iface_xml = _get_interface_xml_by_alias(domain, tap_alias)
    flags = libvirt.VIR_DOMAIN_AFFECT_CONFIG | libvirt.VIR_DOMAIN_AFFECT_LIVE
    try:
        domain.detachDeviceFlags(iface_xml, flags=flags)
        # Wait for device to disappear from domain XML (double-check detach succeeded)
        _wait_for_interface_absent_in_xml(conn, domain_name, tap_name)
    except libvirt.libvirtError as e:
        raise RuntimeError(f"Failed to detach interface from domain: {e}") from e
    finally:
        _delete_tap_interface(tap_name)


def cycle_domain_interface(
        domain_name: str,
        interval: float,
        repeats: int,
        index: int = 0
) -> None:
    conn = libvirt.open()
    for _i in range(repeats):
        name, alias = create_and_attach_interface(conn, domain_name, index)
        time.sleep(interval)
        detach_and_delete_interface(conn, domain_name, name, alias)
        time.sleep(interval)


def setup() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog=PROGRAM_NAME,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "domain",
        help="Name existing libvirt domain",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="interval between attach and detach attempts",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=1,
        help="number of parallel attach/detach workers",
    )
    parser.add_argument(
        "--repeats",
        type=int,
        default=1,
        help="Number of attach/detach cycles per worker",
    )
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    if args.workers > 99:
        raise ValueError("Workers must be less than 100")
    return args


def main() -> None:
    args = setup()
    with futurist.ProcessPoolExecutor(max_workers=args.workers) as pool:
        res = []
        for w in range(args.workers):
            LOG.info(f"starting worker {w}")
            res.append(
                pool.submit(
                    cycle_domain_interface,
                    args.domain,
                    args.interval,
                    args.repeats,
                    index=w,
                )
            )
        done, not_done = waiters.wait_for_all(res)
        if not_done or not all(r.result() for r in done):
            sys.exit(1)


if __name__ == "__main__":
    main()
