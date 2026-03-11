#!/usr/bin/env bash
set -e
STACK_DIR="/opt/stack"
DEVSTACK_DIR="$STACK_DIR/devstack"
STACK_DATA_DIR="$STACK_DIR/data"

eval "$(grep ^SERVICE_HOST $DEVSTACK_DIR/local.conf)"

mkdir -p $STACK_DATA_DIR
scp -r "$SERVICE_HOST:/$STACK_DATA_DIR/CA"  $STACK_DATA_DIR

$DEVSTACK_DIR/stack.sh

ssh "${SERVICE_HOST}" -- $DEVSTACK_DIR/tools/discover_hosts.sh

# TODO: setup all that is needed for (live) migration to work:
# - patch /etc/hosts
# - setup SSH for root
