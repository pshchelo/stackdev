#/usr/bin/env bash
. /opt/stack/devstack/accrc/admin/admin
diskfmt="qcow2"
addimage="glance image-create --is-public True --disk-format $diskfmt --container-format bare"

awslbimage_name="Fedora-Cloud-Base-20141203-21.x86_64"
awslbimage_url="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/$awslbimage_name.$diskfmt"
$addimage --location $awslbimage_url --name $awslbimage_name
#glance image-create --is-public True --disk-format $diskfmt --container-format bare --location $awslbimage_url --name $awslbimage_name

heat_func_image_name="fedora-heat-test-image"
heat_func_image_url="http://tarballs.openstack.org/heat-test-image/$heat_func_image_name.$diskfmt"
$addimage --location $heat_func_image_url --name $heat_func_image_name
#glance image-create --is-public True --disk-format $diskfmt --container-format bare --location $heat_func_image_url --name $heat_func_image_name
