#!/bin/bash

set -ex
WORKDIR=$(readlink -f $0 | xargs dirname)

echo "Building irsible:"

##############################################
# Download and Cache Tiny Core Files
##############################################

cd $WORKDIR/build_files
wget -N http://distro.ibiblio.org/tinycorelinux/7.x/x86_64/release/distribution_files/corepure64.gz
wget -N http://distro.ibiblio.org/tinycorelinux/7.x/x86_64/release/distribution_files/vmlinuz64
