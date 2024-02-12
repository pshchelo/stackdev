#!/usr/bin/env python3
"""
Find disagreements between Nova, Libvirt and Cinder re attached volumes

For MOSK, copy script to osdpl container of openstack-controller pod,
exec into the pod and run like this:

    OS_CLOUD=admin python3.8 <script file>

or run locally, where it needs installed openstacksdk and kubectl.

For MCP, ...? Needs openstacksdk and ssh? run from ctl01? Not implemented yet
"""
import logging
import subprocess
from urllib.parse import urlparse
import xml.etree.ElementTree as ET

import openstack
try:
    from openstack_controller import kube
    kube_api = kube.kube_client()
except ImportError:
    kube_api = None

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger("corrupted-va")

cloud = openstack.connect()
nova = cloud.compute
cinder = cloud.block_storage

IS_MOSK = None


def is_mosk():
    global IS_MOSK
    if IS_MOSK is None:
        keystone_identity_service = cloud.identity.find_service(
            name_or_id="keystone"
        )
        keystone_endpoints = cloud.identity.endpoints(
            service_id=keystone_identity_service.id,
            interface="internal",
        )
        keystone_internal_url = list(keystone_endpoints)[0].url
        IS_MOSK = urlparse(keystone_internal_url).hostname.endswith(
            "svc.cluster.local")
    return IS_MOSK


def get_xml_mcp(server):
    raise NotImplementedError


def get_xml_mosk_kubectl(server):
    find_libvirt_pod = subprocess.run(
        [
            "kubectl", "-n", "openstack", "get", "pod", "-oname",
            "-l", "application=libvirt",
            "--field-selector", "spec.nodeName="+server.compute_host,
        ],
        check=True,
        capture_output=True
    )
    libvirt_pod = find_libvirt_pod.stdout.strip()
    server_xml_call = subprocess.run(
        [
            "kubectl", "-n", "openstack", "exec", libvirt_pod,
            "-c", "libvirt", "--",
            "virsh", "dumpxml", server.id,
        ],
        check=True,
        capture_output=True
    )
    return server_xml_call.stdout


def get_xml_mosk_pykube(server, api):
    libvirt_pods = list(
        kube.Pod.objects(api).filter(
            namespace="openstack",
            selector={"application": "libvirt"},
            field_selector={"spec.nodeName": server.compute_host}
        )
    )
    return libvirt_pods[0].exec(
        ("virsh", "dumpxml", server.id),
        container="libvirt",
    )["stdout"]


def get_disk_info(server):
    if is_mosk():
        if kube_api is None:
            xml_str = get_xml_mosk_kubectl(server)
        else:
            xml_str = get_xml_mosk_pykube(server, kube_api)
    else:
        xml_str = get_xml_mcp(server)
    return parse_disk_info(ET.fromstring(xml_str))


def parse_disk_info(domain_xml):
    disk_info = set()
    for disk in domain_xml.find("devices").findall("disk"):
        # devices for volumes attached volumes have serial element == volume id
        # ET Element w/o children is False, so check for None specifically
        if (serial := disk.find("serial")) is not None:
            disk_info.add(
                (serial.text, "/dev/" + disk.find("target").attrib["dev"])
            )
    return disk_info


def compare_disks_nova_libvirt(server):
    disk_info = get_disk_info(server)
    nova_data = {
        (va.volume_id, va.device)
        for va in nova.volume_attachments(server)
    }
    if disk_info != nova_data:
        LOG.error("nova and libvirt disagree on attached volumes")
        LOG.error("libvirt {}".format(disk_info))
        LOG.error("nova    {}".format(nova_data))


def compare_volumes_nova_cinder(server):
    for nova_va in nova.volume_attachments(server):
        volume = cinder.find_volume(
                name_or_id=nova_va.volume_id, all_projects=True)
        for cinder_va in volume.attachments:
            if cinder_va["server_id"] == server.id:
                if cinder_va["device"] != nova_va.device:
                    LOG.error(
                        "server {server_id} and volume {volume_id} "
                        "disagree on device the volume is attached".format(
                            server_id=server.id, volume_id=volume.id)
                    )
                break
        else:
            LOG.error(
                "nova server {server_id} is attached to "
                "volume {volume_id} in Nova but not in Cinder".format(
                    server_id=server.id, volume_id=volume.id
                )
            )


def process_server(server):
    LOG.info("checking server {}".format(server.id))
    compare_volumes_nova_cinder(server)

    if is_mosk():
        compare_disks_nova_libvirt(server)
    else:
        LOG.warning("fetching libvirt xml is not implemented for MCP, no-op")


if __name__ == "__main__":
    for server in nova.servers(all_projects=True):
        if server.attached_volumes and server.status == "ACTIVE":
            process_server(server)
