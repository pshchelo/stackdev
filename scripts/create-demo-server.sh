#!/usr/bin/env bash
set -e

function usage {
    echo "Usage: $(basename "$0") NAME [FLAVOR [IMAGE] ] [-h]"
    echo "Relies on proper entry in clouds.yaml set via OS_CLOUD env var"
    echo "Expects the project in use to have keypair, network and security group named the same as project"
    echo "Parameters:"
    echo "  NAME   name of the server to create"
    echo "  FLAVOR flavor to use for the server (defaults to 'm1.nano')"
    echo "  IMAGE  image to use for the server (defaults to 'Cirros-6.0')"
    echo "  -v     be verbose (set -x)"
    echo "  -h     show this message and exit"
}

while getopts ':hv' arg; do
    case "${arg}" in
        h) usage; exit 0 ;;
        v) set -x ;;
        *) ;;
    esac
done

server_name=$1
if [ -z "$server_name" ]; then
    echo "Need at least name for the server"
    usage
    exit 1
fi
server_flavor=${2:-m1.nano}
server_image=${3:-Cirros-6.0}
project=$(openstack configuration show -f value -c auth.project_name)
script_dir=$(dirname "$0")
openstack server create "$server_name" \
    --key-name "$project" \
    --network "$project" \
    --security-group "$project" \
    --image "$server_image" \
    --flavor "$server_flavor" \
    --user-data "$script_dir/cirros-http-cpuload.userdata" \
    --use-config-drive \
    --wait

# NOTE: admin sees all FIPs by default, but non-admin always get empty FIP list
# when listing with project, even with their own, so need to differentiate
project_filter=""
if [ "$project" = "admin" ]; then
    project_filter="--project admin"
fi

# shellcheck disable=SC2086 # word splitting in project_filter is intentional
fip=$(openstack floating ip list $project_filter --status DOWN -f value -c 'Floating IP Address' | sort -R | head -n1)
if [ -z "$fip" ]; then
    fip=$(openstack floating ip create public -f value -c floating_ip_address)
fi
openstack server add floating ip "$server_name" "$fip"
echo "$fip"
