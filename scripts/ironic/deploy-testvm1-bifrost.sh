#!/usr/bin/env bash

set -e

node_name="testvm1"
image_store="http://192.168.122.1:8080"

source ~/bifrost/env-vars
ironic node-update ${node_name} remove instance_info
ironic node-update ${node_name} add \
    instance_info/image_source="${image_store}/xenial-parted.qcow2" \
    instance_info/image_checksum="433193c92104e2bae8b64434fff314d4" \
    instance_info/root_gb=10 \
    instance_info/configdrive="${image_store}/configdrive-xenial-parted.iso.gz" \
    instance_info/image_disk_format="qcow2" \
    instance_info/image_container_format="bare" \
    instance_info/kernel="noop" \
    instance_info/ramdisk="noop" \
    instance_info/image_properties='{}' \
    instance_info/image_properties/lvm_partitions='{"root": {"size": "5G", "mount": "/"}, "logs": {"size": "10%VG", "fstype": "ext2", "mount": "/var/log"}}'
ironic node-set-provision-state ${node_name} active
