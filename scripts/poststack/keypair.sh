#!/usr/bin/env bash
. /opt/stack/devstack/accrc/demo/demo
nova keypair-add demo --pub_key $HOME/.ssh/git_rsa.pub
nova keypair-list
