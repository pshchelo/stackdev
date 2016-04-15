=========================================
Irsible - Tiny Core Ironic Ansible Deploy
=========================================

.. WARNING::
    This is experimental! Build tested on Ubuntu Server 14.04

Inspired by code from ``ironic-python-agent/imagebuild/tinyipa``

Build script requirements
-------------------------
For the main build script:

* wget
* pip
* unzip
* sudo
* awk
* mksquashfs

For building an ISO you'll also need:

* genisoimage

Instructions:
-------------
To create a new ramdisk, run::

    make

or::

    make build final

to skip installing dependencies.

This will create two new files once completed:

* irsible.vmlinuz
* irsible.gz

These are your two files to upload to Glance for use with Ironic.

Building an ISO from a previous make run:
-----------------------------------------
Once you've built irsible it is possible to pack it into an ISO if required.
To create a bootable ISO, run::

     make iso

This will create one new file once completed:

* irsible.iso

To build a fresh ramdisk and build an iso from it:
--------------------------------------------------
Run::

    make all

To clean up the whole build environment run:
--------------------------------------------
Run::

    make clean

For cleaning up just the iso or just the ramdisk build::

    make clean_iso

or::

    make clean_build clean_final

SSH access
----------

The user with configured SSH access is ``tc`` (default user in TinyCore).

By default the key ``$HOME/.ssh/id_rsa.pub`` is put in ``tc`` user's
``authrozed_keys``. To supply another public key, set this variable in the shell
before building the image::

    export IRSIBLE_SSH_KEY=<path-to-the-public-key>

Bootstrapping for use with Ansible
----------------------------------

Current version only installs, configures and starts SSHd on the image.
To effectively use Ansible you must install Python on the image as well::

    tce-load -wis python

On TinnyCore the installed Python is located as ``/usr/local/bin/python``.
To use Ansible without setting the custom ``anible_python_interpreter``
in the inventory create a symlink to the location expected by Ansible::

    sudo ln -s /usr/local/bin/python /usr/bin/python

The provided ``bootstrap.yaml`` Ansible playbook will do the two steps
above for you. Include it in your playbooks when working with this image.
