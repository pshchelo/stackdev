#!/usr/bin/env bash
set -e

function print_help {
    echo "$0 - operations on KaaS cluster"
    echo "Usage: $0 CLUSTER_NAME [--list|--ssh|--cmd]"
    echo "ENV vars: KAAS_REALM, KAAS_CONTEXT, KAAS_PRIVATE_KEY, KAAS_SSH_USER"
}

function ssh_to_master_node {
    local cmd=$@
    node_ip=$(${kube_get_machines} | jq -r '.items[].metadata | select(.labels."cluster.sigs.k8s.io/control-plane"=true) | .annotations."openstack-floating-ip-address"' | head -n1)
    if [ -z $node_ip ]; then
        echo "No control plane nodes found for cluster $cluster"
        exit 1
    fi
    ${sshcmd} $node_ip "${cmd}"
}

function list_cluster_nodes {
    ${kube_get_machines} | \
        jq '.items[].metadata | {name: .name, "control-plane": .labels."cluster.sigs.k8s.io/control-plane", "instance-id": .annotations."openstack-resourceId", "kaas-node": ("kaas-node-" + .annotations."kaas.mirantis.com/uid"), ip: .annotations."openstack-floating-ip-address"}'
}

function run_cmd {
    local cmd=$@
    for node_ip in $(${kube_get_machines} | jq -r '.items[].metadata.annotations."openstack-floating-ip-address"'); do
        ${sshcmd} $node_ip hostname
        ${sshcmd} $node_ip "${cmd}" || true
        echo
    done
}


realm=${KAAS_REALM:-imc-oscore-team}
context=${KAAS_CONTEXT:-pshchelokovskyy@kaas}
ssh_key=${KAAS_PRIVATE_KEY:-"~/.ssh/aio_rsa"}
ssh_user=${KAAS_SSH_USER:-ubuntu}
kubecmd="kubectl --context ${context} -n ${realm}"
sshcmd="ssh -i ${ssh_key} -l ${ssh_user} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET"

cluster=$1
if [ -z $cluster ]; then
    print_help
    exit 1
fi
kube_get_machines="${kubecmd} get machine -l cluster.sigs.k8s.io/cluster-name=${cluster} -ojson"

shift
case $1 in
    "--ssh")
        shift
        ssh_to_master_node $*
        ;;
    "--list")
        shift
        list_cluster_nodes
        ;;
    "--cmd")
        shift
        run_cmd $*
        ;;
    *)
        ${kube_get_machines}
esac
