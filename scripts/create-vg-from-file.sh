#!/bin/sh
# run under sudo

DEFAULT_DISK_FILE="/srv/cinder-lvm-pv"
DEFAULT_DISK_SIZE="50G"
DEFAULT_VG_NAME="cinder-vol"

__usage="
create-vg-from-file.sh [-f FILE] [-s SIZE] [-n NAME]

Parameters:
    -f FILE - path to backing file to create and allocate
              Default is $DEFAULT_DISK_FILE
    -s SIZE - size of the file to allocate, in format accepted by 'fallocate'.
              Default is $DEFAULT_DISK_SIZE
    -n NAME - Name of the Volume Group to create.
              Default is $DEFAULT_VG_NAME
"

DISK_FILE="$DEFAULT_DISK_FILE"
DISK_SIZE="$DEFAULT_DISK_SIZE"
VG_NAME="$DEFAULT_VG_NAME"
while getopts ':hf:s:n:' arg; do
    case "${arg}" in
        f) DISK_FILE="${OPTARG}";;
        s) DISK_SIZE="${OPTARG}";;
        n) VG_NAME="${OPTARG}";;
        h) echo "$__usage"; exit 0;;
        *) echo "$__usage"; exit 1;;
    esac
done

vgs -a --noheadings -o vg_name | grep "$VG_NAME" || exit 1
test -f "$DISK_FILE" && exit 1
fallocate -l "$DISK_SIZE" "$DISK_FILE"
pv_name=$(losetup --show -f "$DISK_FILE")
pvcreate "$pv_name"
vgcreate "$VG_NAME" "$pv_name"
