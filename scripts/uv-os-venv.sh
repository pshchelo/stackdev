#!/usr/bin/env bash

os_release=${1:-master}

case $os_release in
    "gazpacho")
        os_release="2026.1";;
    "epoxy")
        os_release="2025.1";;
    "caracal")
        os_release="2024.1";;
esac

uv venv
uv pip install \
    -r requirements.txt \
    -r test-requirements.txt \
    -c "https://releases.openstack.org/constraints/upper/${os_release}"
