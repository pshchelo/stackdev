#!/usr/bin/env bash
# installs a pipx env with python-openstackclient and all plugins
# for services supported in MOSK
# the rest are either non-OpenStack services/components,
# OpenStack but do not have HTTP API (like metering (ceilometer)),
# or are deprecated in MOSK (like events(panko))
pipx install python-openstackclient # supports Keystone, Nova, Glance, Cinder, Neutron, Swift
pipx inject python-openstackclient \
    python-heatclient \
    python-designateclient \
    python-masakariclient \
    aodhclient \
    gnocchiclient \
    python-ironicclient \
    python-barbicanclient \
    osc-placement \
    python-octaviaclient # this one better from downstream for support of --force
openstack complete > ~/.local/share/bash-completion/completions/openstack
