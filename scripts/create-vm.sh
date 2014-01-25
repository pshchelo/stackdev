virt-install \
	--connect qemu:///system \
	--virt-type kvm \
	--name vm2-2 \
	--ram 500 \
	--disk path=/var/lib/libvirt/images/vm2-2.qcow2,format=qcow2 \
	--network bridge=virbr0 \
	--boot hd \
        --noautoconsole \
