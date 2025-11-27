#!/usr/bin/env bash
set -e
# Preparations to work with fresh MOSK virtual dev cluster
RED='\033[0;31m'
NOC='\033[0m'
READONLY=0
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")
__usage="
Usage: $SCRIPT_NAME [-r] <URL>
Prepare (virtual) MOSK development env for my custom settings:
- fetch and massage kubeconfig
- create local copies of main MOSK k8s resources like OsDpl
- create test user accounts, networks, flavors etc

<URL> URL to deploy job with 'kubeconfig-child-cluster.yml' artifact
-r    read-only mode, do not create test user accounts, networks etc
"
while getopts ':hr' arg; do
    case "$arg" in
        r) READONLY=1 ;;
        h) echo "$__usage"; exit 0 ;;
        *) echo "$__usage"; exit 1 ;;
    esac
done
shift $((OPTIND-1))
url=$1
if [ -z "$url" ]; then
    echo "$__usage"
    exit 1
fi
echo "Get kubeconfig for the env"
wget "$url/artifact/kubeconfig-child-cluster.yml" -O kubeconfig.yaml
echo "Edit kubeconfig for the env"
"$SCRIPT_DIR"/mosk-dev-config-rename-context.sh kubeconfig.yaml
cat > "$PWD/.envrc" << EOF
export KUBECONFIG="\$PWD/kubeconfig.yaml"
export OS_CLOUD="mosk-dev-admin"
EOF
direnv allow
source "$PWD/.envrc"
echo "Create local copies of deployed resources"
"$SCRIPT_DIR"/mosk-dev-fetch-deployed-resources.sh
if [ $READONLY -eq 0 ]; then
    echo -e "${RED}START mosk-dev-connect in a separate shell NOW${NOC}"
    sleep 5
    # the next command needs mosk-dev-connect running,
    # but it will pause if that is not running yet
    echo "Create my default test env users and infra"
    "$SCRIPT_DIR"/mosk-dev-create-resources.sh
fi
