#!/usr/bin/env bash
# Create a VM via virt-manager and libvirt using cloud image as a base
# Expects base image to be qcow2 and having cloud-init installed in it

set -e
VM_NAME=$1
VM_BASE_IMAGE=$2
VM_OS_VARIANT=$3

VM_POOL_PATH=${VM_POOL_PATH:-"/var/lib/libvirt/images"}
VM_SSH_KEY=${VM_SSH_KEY:-"${HOME}/.ssh/pub/aio_rsa.pub"}
VM_DISK_SIZE=${VM_DISK_SIZE:-"20"}
VM_CPUS=${VM_CPUS:-"2"}
VM_MEMORY=${VM_MEMORY:-"4096"}
VM_NETWORK=${VM_NETWORK:-"default"}
VM_ARCH=${VM_ARCH:-"x86_64"}

VM_DISK_PATH="${VM_POOL_PATH}/${VM_NAME}.qcow2"

sudo qemu-img create -F qcow2 -b "${VM_BASE_IMAGE}" -f qcow2 "${VM_DISK_PATH}" "${VM_DISK_SIZE}G"

meta_data_file=$(mktemp)
user_data_file=$(mktemp)

cleanup() {
    rm "$meta_data_file"
    rm "$user_data_file"
    echo "cleaned up temporary files"
}

trap cleanup 1 2 3 6 EXIT

cat > "$meta_data_file" << EOF
instance_id: $VM_NAME
local-hostname: $VM_NAME
EOF

cat > "$user_data_file" << EOF
#cloud-config
create_hostname_file: true
ssh_authorized_keys:
- "$(cat "$VM_SSH_KEY")"
EOF

virt-install \
    --name "${VM_NAME}" \
    --import \
    --disk path="${VM_DISK_PATH}",format=qcow2 \
    --vcpus="${VM_CPUS}" \
    --memory="${VM_MEMORY}" \
    --network "network=${VM_NETWORK},model=virtio" \
    --osinfo "${VM_OS_VARIANT}" \
    --arch "${VM_ARCH}" \
    --graphics vnc,listen=0.0.0.0 \
    --cpu host-passthrough,cache.mode=passthrough \
    --cloud-init "disable=on,meta-data=$meta_data_file,user-data=$user_data_file" \
    --virt-type kvm \
    --watchdog=default \
    --noautoconsole

# TODO: wait for IP address available and parse it from `virsh domifaddr $VM_NAME`
