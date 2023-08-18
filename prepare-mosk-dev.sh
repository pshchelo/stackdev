#!/usr/bin/env bash
basedir=$(dirname "$0")
pod=$(kubectl -n openstack get pod -l application=keystone,component=client -ojsonpath='{.items[0].metadata.name}')
if [ -f ~/.ssh/pub/aio_rsa.pub ]; then
    kubectl -n openstack cp ~/.ssh/pub/aio_rsa.pub $pod:/tmp/pubkey -c keystone-client
fi
kubectl -n openstack cp ${basedir}/mosk-dev-create-resources.sh $pod:/tmp/mosk-dev-create-resources.sh -c keystone-client
kubectl -n openstack exec -ti $pod -c keystone-client -- bash /tmp/mosk-dev-create-resources.sh
