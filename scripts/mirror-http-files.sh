#!/usr/bin/env bash
# downloads whole site ignoring index.htm[l] files
URL=$1
if [ -z "${URL}" ]; then
    echo "need URL to mirror files from"
    exit 1
fi
# TODO: accept regexes for --reject as input
# TODO: infer CUT_DIRS from URL
CUT_DIRS=3 # https://artifactory.mcp.mirantis.net/artifactory/oscore-local/mcp2
wget --mirror \
     --no-host-directories \
     --no-parent \
     --cut-dirs ${CUT_DIRS} \
     --reject='index.htm*' \
     "${URL}/"
