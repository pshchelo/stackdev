#!/bin/sh
# put other system startup commands here

#exec > /tmp/installlogs 2>&1
set -x

echo "Starting bootlocal script:"
date

# Start SSHd
/usr/local/etc/init.d/openssh start
