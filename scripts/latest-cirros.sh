#!/usr/bin/env bash

CREDS=/opt/stack/devstack/openrc
CIRROS_VERSION="0.3.4"
CIRROS_ARCH="x86_64"
CIRROS_QCOW_IMAGE="cirros-${CIRROS_VERSION}-${CIRROS_ARCH}-disk"
CIRROS_QCOW_IMAGE_URL="http://download.cirros-cloud.net/${CIRROS_VERSION}/${CIRROS_QCOW_IMAGE}.img"

. ${CREDS} admin admin
curl ${CIRROS_QCOW_IMAGE_URL} | glance image-create \
                                       --progress \
                                       --is-public True \
                                       --disk-format qcow2 \
                                       --container-format bare \
                                       --name cirros \
                                       --property description=${CIRROS_QCOW_IMAGE} \
