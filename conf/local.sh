#! /usr/bin/env bash
set -x
OSDEMO="openstack --os-cloud devstack"
OSADMIN="openstack --os-cloud devstack-admin"
CATALOG=$(${OSADMIN} catalog list -f value -c Name)

function has_services {
    services=$@
    for service in ${services}; do
        grep -q ${service} <<<${CATALOG} || return 1
    done
    return 0
}

function add_completions {
    # create BASH completions for openstack client
    local completions_dir=~/.local/share/bash-completion/completions
    mkdir -p $completions_dir
    openstack complete > $completions_dir/openstack
}

function patch_ironic_vnc {
    if has_services ironic; then
        # patch vnc settings on ironic's fake BM nodes
        sudo python${python_version} ${HOME}/stackdev/scripts/ironic/setvirtvnc.py
    fi
}

function patch_system {
    # General changes to the system and installed packages
    local python_version='2'
    #echo "Am I using Python3?" $USE_PYTHON3
    if [ $USE_PYTHON3 == "True" ]; then
        python_version='3'
    fi
    local pypkg_to_remove="flake8-docstrings
                           openstack.nose-plugin"
    for pypkg in $pypkg_to_remove; do
        if [ $(pip${python_version} freeze | grep $pypkg) ]; then
            sudo -H pip${python_version} uninstall -y $pypkg
        fi
    done
}

function allow_wan {
    WAN_SET=$(sudo iptables -t nat -L | grep "MASQUERADE.*all.*anywhere.*anywhere")
    if [ -z "$WAN_SET" ]; then
        echo "Allowing WAN access for VMs..."
        sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    else
        echo "WAN access is already allowed."
    fi
}

function add_keypairs {
    if ! has_services nova; then
        echo "Nova is not installed, skip adding keypair"
        return
    fi
    ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
    echo "Adding demo keypair..."
    ${OSDEMO} keypair create demo --public-key ~/.ssh/id_rsa.pub
    ${OSADMIN} keypair create admin --public-key ~/.ssh/id_rsa.pub

}

function create_minimal_flavor {
    if ! has_services nova; then
        echo "Nova is not installed, skip creating flavor"
        return
    fi

    if ! ${OSADMIN} flavor show m1.nano -f value -c name ; then
        ${OSADMIN} flavor create m1.nano --vcpus 1 --disk 1 --ram 128
    fi
}

function create_networks {
    if ! has_services neutron; then
        echo "Neutron is not installed, skip creating networks"
        return
    fi
    PRIVATE_SUBNET_CIDR=10.11.12.0/24
    ${OSDEMO} router create demo --external-gateway public
    ${OSDEMO} network create demo
    ${OSDEMO} subnet create demo --network demo --subnet-range "${PRIVATE_SUBNET_CIDR}"
    ${OSDEMO} router add subnet demo demo

    ${OSADMIN} router create admin --external-gateway public
    ${OSADMIN} network create admin
    ${OSADMIN} subnet create admin --network admin --subnet-range "${PRIVATE_SUBNET_CIDR}"
    ${OSADMIN} router add subnet admin admin
}

function add_dns {
    if ! has_services neutron; then
        echo "Neutron is not installed, skip adding DNS."
    fi
    echo "Adding Google DNS to demo tenant private subnets..."
    dnsserver4=8.8.8.8
    subnet4=$(${OSDEMO} subnet list --name private-subnet -f value -c ID)
    ${OSDEMO} subnet set $subnet4 --dns-nameserver $dnsserver4
    ${OSDEMO} subnet show $subnet4
    subnet6=$(${OSDEMO} subnet list -f value --name ipv6-private-subnet -c ID)
    if [ -n "${subnet6}" ]; then
        dnsserver6="2001:4860:4860::8888"
        ${OSDEMO} subnet set $subnet6 --dns-nameserver $dnsserver6
        ${OSDEMO} subnet show $subnet6
    fi
}

function add_heat_net {
    if ! has_services heat neutron; then
        echo "Heat or Neutron not installed, skip adding Heat test network."
        return
    fi
    echo "Adding subnet for heat tests..."
    # create a heat specific private network
    # default 'private' network of the 'demo' project has second, ipv6 subnet
    # which breaks heat tests as the order of instance IPs returned is random
    HEAT_PRIVATE_SUBNET_CIDR=10.0.5.0/24
    ${OSDEMO} network create heat-net
    ${OSDEMO} subnet create heat-subnet --network heat-net --subnet-range "${HEAT_PRIVATE_SUBNET_CIDR}"
    ${OSDEMO} router add subnet router1 heat-subnet

    if command -v jq; then
        PUB_SUBNET_ID=$(${OSADMIN} subnet list --name public-subnet -f value -c ID)
        PUB_SUBNET_PORT_ID=$(${OSADMIN} port list --device-owner network:router_gateway --fixed-ip subnet=public-subnet -f value -c ID)
        ROUTER_GW_IP=$(${OSADMIN} port show ${PUB_SUBNET_PORT_ID} -fjson | jq -r --arg SUBNET_ID "$PUB_SUBNET_ID" '.fixed_ips[] | select(.subnet_id==$SUBNET_ID) | .ip_address')
        sudo route add -net "${HEAT_PRIVATE_SUBNET_CIDR}" gw "${ROUTER_GW_IP}"
    else
        echo "Jq tool not available, skip adding Heat network to local routes"
    fi
}

function secgroup {
    if ! has_services neutron; then
        echo "Neutron is not installed, skip modifying default security groups."
        return
    fi
    echo "Adding ingress ICMP and SSH to default security group of demo user..."
    # NOTE: openstackclient currently manages secgroups via nova client,
    #       which understands only ingress rules,
    #       and this is exactly what I need
    ${OSDEMO} security group rule list default -f value -c ID | xargs -L1 ${OSDEMO} security group rule delete
    ${OSDEMO} security group rule create default --proto icmp --remote-ip "0.0.0.0/0"
    ${OSDEMO} security group rule create default --proto tcp --remote-ip "0.0.0.0/0" --dst-port 22
}

function run_default {
    add_keypairs
    create_minimal_flavor
    create_networks
    #add_completions  # not needed any more it seems, destack does that globally
    #patch_system     # not needed any more, especially if deployed in a venv
    #allow_wan        # is it really needed?
    #secgroups        # not needed by default?
    #add_dns          # is it really needed?
    #patch_ironic_vnc # is it still needed?
}


# sanitize env from OS_* vars
for v in $(env | grep ^OS_ | awk -F = '{print($1)}'); do
    unset "$v"
done

if [ $# -eq 0 ]; then
    run_default
    exit $?
fi

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            echo -e "Supported options: patch wan key dns secgroup heatnet\nDefault - all the above"
            exit 1
        ;;
        infra)
            create_infra
            shift # past argument
        ;;
        patch)
            patch_system
            shift # past argument
        ;;
        wan)
            allow_wan
            shift # past argument
        ;;
        dns)
            add_dns
            shift # past argument
        ;;
        secgroup)
            secgroup
            shift
        ;;
        heatnet)
            add_heat_net
            shift
        ;;
        *)
            echo -e "Unregognized option $key\nRun with -h to see available options"
            exit 1
        ;;
    esac
    shift # past argument or value
done
