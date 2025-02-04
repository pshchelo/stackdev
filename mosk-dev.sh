#!/usr/bin/env bash
set -e
# Preparations to work with fresh MOSK virtual dev cluster
RED='\033[0;31m'
NOC='\033[0m'

if [ -z "$1" ]; then
    echo "need URL to deploy job with 'kubeconfig-child-cluster.yml' artifact"
    exit 1
fi
echo "Get kubeconfig for the env"
wget "$1/artifact/kubeconfig-child-cluster.yml" -O kubeconfig.yaml
echo "Edit kubeconfig for the env"
~/dotfiles/scripts/mosk/mosk-dev-config-rename-context.sh kubeconfig.yaml
cat > .envrc << EOF
export KUBECONFIG="\$PWD/kubeconfig.yaml"
export OS_CLOUD="mosk-dev-admin"
EOF
direnv allow
source .envrc
echo -e "${RED}START mosk-dev-connect in a separate shell NOW${NOC}"
sleep 5
echo "Create local copies of deployed resources"
~/dotfiles/scripts/mosk/mosk-dev-fetch-deployed-resources.sh
# the next command needs mosk-dev-connect running,
# but it will pause if that is not running yet
echo "Create my default test env users and infra"
~/dotfiles/scripts/mosk/mosk-dev-create-resources.sh
