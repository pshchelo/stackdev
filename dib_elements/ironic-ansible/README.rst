==============
ironic-ansible
==============

Builds a ramdisk for Ironic Ansible deploy driver.

Uses ``devuser`` element to create a user with passwordless sudo permissions
and adds SSH keys for that user.

The ansible-deploy driver in Ironic by default expects user named ``ansible``,
but this can be changed in driver properties on per-node basis.

You must set DIB_DEV_USER_PWDLESS_SUDO environment variable for this image.

See the ``devuser`` element README for more instructions
and available settings.

Simplest example::

    export DIB_DEV_USER_USERNAME=ansible
    export DIB_DEV_USER_PWDLESS_SUDO=yes
    export DIB_DEV_USER_AUTHORIZED_KEYS=<path-to-the-private-key>
    disk-image-create -o ir-ansible-deploy ubuntu-minimal ironic-ansible

Apart from setting the user, this element:

- sets the hostname to ``ironic-ansible-deploy``
  and adds it to ``/etc/hosts``;
- installs OpenSSH server;
- disables firewall service (``iptables``/``ufw`` depending on init system);
- Installs the ``dhcp-all-interfaces`` so the node, upon booting,
  attempts to obtain an IP address on all available network interfaces;
- Installs some tools for node provisioning

  - util-linux
  - parted
  - qemu-utils
