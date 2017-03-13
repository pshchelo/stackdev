#!/usr/bin/env bash
tmpkey=/tmp/ssh_tmp_pub_key_file

# relies on building user name to be present as account on GitHub
wget https://github.com/"${USER}".keys -O $tmpkey

IMAGE_BASE=${1:-'ubuntu'}
RELEASE=${2:-'xenial'}
SIZE=${3:-'50'}

export DIB_DEV_USER_USERNAME="${USER}"
export DIB_DEV_USER_PWDLESS_SUDO=true
export DIB_DEV_USER_AUTHORIZED_KEYS=$tmpkey
export DIB_DEV_USER_SHELL='/bin/bash'
export DIB_RELEASE=${RELEASE}

disk-image-create \
    ${IMAGE_BASE} vm growroot cloud-init-nocloud devuser \
    -a amd64 --image-size ${SIZE} \
    -o "${USER}-${IMAGE_BASE}-${RELEASE}-virt-base-${SIZE}G"

rm $tmpkey
