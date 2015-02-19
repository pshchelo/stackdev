#!/usr/bin/env bash
. /opt/stack/devstack/accrc/demo/demo
nova keypair-add demo > $HOME/demo.pem
chmod 600 $HOME/demo.pem
nova keypair-list
