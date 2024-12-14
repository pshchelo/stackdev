#!/usr/bin/env bash
VM_NAME=$1
VM_SSH_KEY=$2
isodir=$(mktemp -d)

cleanup() {
    rm -rf "$isodir"
    echo "cleaned up temporary files"
}

trap cleanup 1 2 3 6 EXIT

cat > "${isodir}/meta-data" << EOF
instance_id: $VM_NAME
local-hostname: $VM_NAME
EOF

cat > "${isodir}/user-data" << EOF
#cloud-config
create_hostname_file: true
ssh_authorized_keys:
- "$(cat "$VM_SSH_KEY")"
EOF

# example command to generate proper ISO file for manual qemu invocation
# Linux - genisoimage or mkisofs
pushd $isodir
genisoimage -output cloudinit.iso -volid cidata -joliet -rock user-data meta-data
#mkisofs -output cloudinit.iso -volid cidata -joliet -rock user-data meta-data
popd
mv $isodir/cloudinit.iso ./$VM_NAME.config.iso
# MacOSX - hdiutil (confg/ contains meta-data and user-data files)
#hdiutil makehybrid -o init.iso -hfs -joliet -iso -default-volume-name cidata ${isodir}/
