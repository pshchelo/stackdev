#########################################
Irsible - Tiny Core Ironic Ansible Deploy
#########################################

.. WARNING::
    This is experimental! Build tested on Ubuntu Server 14.04

Inspired by code from ``ironic-python-agent/imagebuild/tinyipa``


Build script requirements
=========================
For the main build script:

* wget
* pip
* unzip
* sudo
* awk
* mksquashfs

For building an ISO you'll also need:

* genisoimage


Bild Instructions:
==================
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


Advanced options
================

SSH access keys
---------------

The user with configured SSH access is ``tc`` (default user in TinyCore).

By default the key ``$HOME/.ssh/id_rsa.pub`` is put in ``tc`` user's
``authrozed_keys``. To supply another public key, set this variable
in the shell before building the image::

    export IRSIBLE_SSH_KEY=<path-to-the-public-key>

Creating a bare-minimal image
-----------------------------

By default the build process will also install Python into the image,
so that is becomes usable with Ansible right away.
If you want to create a very bare-minimal image to have it smaller and
install everything at run-time, set this variable in the shell
before building the image::

    export IRSIBLE_FOR_ANSIBLE=false

To use such image with Ansible, you will have to install Python and symlink
it to a location expected by Ansible
(or set this variable in your Ansible inventory)::

    ansible_python_interpreter=/usr/local/bin/python

The provided ``bootstrap.yaml`` Ansible playbook will do these steps for you.
You can include it in your playbooks when working with this image.

Creating minimal image for Ansible
----------------------------------

By default build script creates an image suitable for Ironic's ansible-deploy
driver, which includes installing (and building) some TC packages.
If you just want to build a minimal Ansible "slave", set this variable in the
shell before building the image::

    export IRSIBLE_FOR_IRONIC=false

Note
    This variable is ignored if ``IRSIBLE_FOR_ANSIBLE`` is set to ``false``.

Note for Ansible users
    This image is very stripped down.

    It obviously lacks any standard package manager like ``apt`` or ``yum``,
    but is also powered by `busybox`, lacks ``bash``
    and many standard GNU tools -
    do not rely on them in your Ansible playbooks.

    On the other hand those can be installed at run-time with
    ``tce-load -wi coreutils util-linux bash``,
    so you can easily extend the ``bootstrap.yaml`` playbook.

    http://tinycorelinux.net/faq.html#compatibility
