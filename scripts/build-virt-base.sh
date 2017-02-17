#!/usr/bin/env bash
tmpkey=/tmp/ssh_tmp_pub_key_file

wget https://github.com/"${USER}".keys -O $tmpkey

IMAGE_BASE=${2:-'ubuntu'}
RELEASE=${3:-'xenial'}
SIZE=${4:-'50'}
OUT_NAME=${1:-"${USER}-${IMAGE_BASE}-${RELEASE}-virt-base-${SIZE}G"}

export DIB_DEV_USER_USERNAME="${USER}"
export DIB_DEV_USER_PWDLESS_SUDO=true
export DIB_DEV_USER_AUTHORIZED_KEYS=$tmpkey
export DIB_DEV_USER_SHELL='/bin/bash'
export DIB_RELEASE=${RELEASE}

disk-image-create \
    ${IMAGE_BASE} vm growroot cloud-init-nocloud devuser \
    -a amd64 --image-size ${SIZE} \
    -o "${OUT_NAME}"

rm $tmpkey
