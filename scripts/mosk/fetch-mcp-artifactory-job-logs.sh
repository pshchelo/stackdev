#!/usr/bin/env bash
ARTIFACTORY_URL=${ARTIFACTORY_URL:-https://artifactory.mcp.mirantis.net/artifactory/oscore-local/mcp2}
JOB=$1
if [ -z "$JOB" ]; then
    echo need job name to download for
    exit 1
fi
wget --mirror \
     --no-host-directories \
     --no-parent \
     --cut-dirs 3 \
     --reject="index.htm*" \
     "$ARTIFACTORY_URL/$JOB/"
