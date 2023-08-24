#!/usr/bin/env bash
server=$1
key=${2:-~/.ssh/aio_rsa}
aiossh="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $key"
$aiossh -l ubuntu $server -- sudo cat /root/.kube/config | sed 's/certificate-authority-data.*$/insecure-skip-tls-verify: true/' | sed "s/server: https.*/server: https:\/\/$server:6443/"
