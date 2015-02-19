#!/usr/bin/env bash
done=$(sudo iptables -t nat -L | grep 'MASQUERADE.*all.*anywhere.*anywhere')
if [ -z "$done" ]; then
    echo "Allowing WAN access for VMs"
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
fi
