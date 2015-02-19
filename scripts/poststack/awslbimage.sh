#/usr/bin/env bash
. /opt/stack/devstack/accrc/admin/admin
awslbimage_name="Fedora-Cloud-Base-20141203-21.x86_64"
awslbimage_url="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/Fedora-Cloud-Base-20141203-21.x86_64.qcow2"
glance image-create --progress --is-public True --disk-format qcow2 --container-format bare --location $awslbimage_url --name $awslbimage_name
