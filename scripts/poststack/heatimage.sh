#/usr/bin/env bash
. /opt/stack/devstack/accrc/admin/admin
diskfmt="qcow2"
addimage="glance image-create --is-public True --disk-format $diskfmt --container-format bare --copy from"

heat_func_image_name="fedora-heat-test-image"
heat_func_image_url="http://tarballs.openstack.org/heat-test-image/$heat_func_image_name.$diskfmt"
$addimage $heat_func_image_url --name $heat_func_image_name
