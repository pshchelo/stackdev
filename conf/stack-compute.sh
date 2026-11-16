#!/usr/bin/env bash

# Deploy devstack compute node
# Run this script on the devstack compute node.
# Pre-requisites:
# - devstack controller is already deployed
# - local.conf for this compute is prepared
# - SSH access for the user running this script to the devstack controller

set -e
STACK_DIR="/opt/stack"
DEVSTACK_DIR="$HOME/Projects/openstack/devstack"
STACK_DATA_DIR="$STACK_DIR/data"

# discover controller IP from prepared devstack config
eval "$(grep ^SERVICE_HOST "$DEVSTACK_DIR/local.conf")"

# fetch TLS artifacts from controller
mkdir -p $STACK_DATA_DIR
scp -r "$SERVICE_HOST:/$STACK_DATA_DIR/CA"  $STACK_DATA_DIR

# deploy compute
"$DEVSTACK_DIR"/stack.sh

# join compute into nova immediately
ssh "${SERVICE_HOST}" -- "$DEVSTACK_DIR/tools/discover_hosts.sh"
