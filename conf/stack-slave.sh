#!/usr/bin/env bash
set -e
controller=$1

if [ -z $controller ]; then
    echo "need controller hostname or IP for SSH access"
    exit 1
fi

scp -r $controller:/opt/stack/data/CA  /opt/stack/data
scp $controller:/opt/stack/data/*.pem /opt/stack/data

pushd /opt/stack/devstack
./stack.sh
popd

ssh $controller -- /opt/stack/devstack/tools/discover_hosts.sh
