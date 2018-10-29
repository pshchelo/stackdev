#!/usr/bin/env bash

SERVER_CLOUD=${SERVER_CLOUD:-'devstack'}
SERVER_NAME=${SERVER_NAME:-'test'}
SERVER_KEY=${SERVER_KEY:-'demo'}
SERVER_FLAVOR=${SERVER_FLAVOR:-'baremetal'}
SERVER_IMAGE=${SERVER_IMAGE:-'cirros-0.3.5-x86_64-disk'}


openstack --os-cloud ${SERVER_CLOUD} server create ${SERVER_NAME} \
    --key-name ${SERVER_KEY} \
    --flavor  ${SERVER_FLAVOR} \
    --image ${SERVER_IMAGE}
