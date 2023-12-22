#!/usr/bin/env python3
"""
Find disagreements between Nova, Libvirt and Cinder re attached volumes

For MOSK, run from osdpl container of openstack-operator pod, or
needs openstacksdk and kubectl.

For MCP, ...? Needs openstacksdk and ssh?
"""
import subprocess
from urllib.parse import urlparse
import xml.etree.ElementTree as ET

import openstack
try:
    from openstack_controller import kube
    kube_api = kube.get_client()
except ImportError:
    kube_api = None

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
    if api is None:
        raise NotImplementedError("Needs openstack-controller code")
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
    disk_info = []
    for disk in domain_xml.find("devices").findall("disk"):
        d = {}
        # TODO: parse out info required for comparison
        disk_info.append(d)
    return disk_info


def compare_disks_nova_libvirt(server):
    nova_vas = list(nova.volume_attachments(server))
    disk_info = get_disk_info(server)
    # TODO: actual comparison


def compare_volumes_nova_cinder(server):
    nova_vas = list(nova.volume_attachments(server))
    cinder_volumes = [cinder.find_volume(
            name_or_id=nova_va.volume_id, all_projects=True
        ) for nova_va in nova_vas]
    # TODO: actual comparison


def process_server(server):
    compare_volumes_nova_cinder(server)
    compare_disks_nova_libvirt(server)


if __name__ == "__main__":
    for server in nova.servers(all_projects=True):
        process_server(server)
