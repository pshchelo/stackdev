#/usr/bin/env bash
. /opt/stack/devstack/accrc/admin/admin

name=$(glance image-list | grep -o "cirros-.*-disk")

glance image-update $name --name cirros --property description=$name
