#/usr/bin/env bash
. /opt/stack/devstack/accrc/admin/admin
diskfmt="qcow2"
addimage="glance image-create --is-public True --disk-format $diskfmt --container-format bare --copy from"

awslbimage_name="Fedora-Cloud-Base-20141203-21.x86_64"
awslbimage_url="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/$awslbimage_name.$diskfmt"
$addimage $awslbimage_url --name $awslbimage_name
