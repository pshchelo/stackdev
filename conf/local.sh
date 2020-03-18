#! /usr/bin/env bash
set -x
OSDEMO="openstack --os-cloud devstack"
OSADMIN="openstack --os-cloud devstack-admin"
CATALOG=`${OSADMIN} catalog list -f value -c Name`

# sanitize env from OS_* vars
function reset_os_vars {
    for v in `env | grep ^OS_ | awk -F = '{print($1)}'`; do
        unset $v
    done
}

function has_services {
    services=$@
    for service in ${services}; do
        grep -q ${service} <<<${CATALOG} || return 1
    done
    return 0
}

function patch_system {
    # create BASH completions for openstack client
    local completions_dir=~/.local/share/bash-completion/completions
    mkdir -p $completions_dir
    openstack complete > $completions_dir/openstack
    # General changes to the system and installed packages
    local python_version='2'
    #echo "Am I using Python3?" $USE_PYTHON3
    if [ $USE_PYTHON3 == "True" ]; then
        python_version='3'
    fi
    local pypkg_to_remove="flake8-docstrings
                           openstack.nose-plugin"
    for pypkg in $pypkg_to_remove; do
        if `pip${python_version} freeze | grep $pypkg`; then
            sudo -H pip${python_version} uninstall -y $pypkg
        fi
    done
    if has_services ironic; then
        # patch vnc settings on ironic's fake BM nodes
        sudo python${python_version} ${HOME}/stackdev/scripts/ironic/setvirtvnc.py
    fi
}

function allow_wan {
    WAN_SET=`sudo iptables -t nat -L | grep "MASQUERADE.*all.*anywhere.*anywhere"`
    if [ -z "$WAN_SET" ]; then
        echo "Allowing WAN access for VMs..."
        sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    else
        echo "WAN access is already allowed."
    fi
}

function add_keypair {
    if has_services nova; then
        ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
        echo "Adding demo keypair..."
        ${OSDEMO} keypair create demo --public-key ~/.ssh/id_rsa.pub
    else
        echo "Nova is not installed, skip adding keypair"
    fi
}

function add_dns {
    if has_services neutron; then
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
    else
        echo "Neutron is not installed, skip adding DNS."
    fi
}

function add_heat_net {
    if has_services heat neutron; then
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
    else
        echo "Heat or Neutron not installed, skip adding Heat test network."
    fi
}

function secgroup {
    if has_services neutron; then
        echo "Adding ingress ICMP and SSH to default security group of demo user..."
        # NOTE: openstackclient currently manages secgroups via nova client,
        #       which understands only ingress rules,
        #       and this is exactly what I need
        ${OSDEMO} security group rule list default -f value -c ID | xargs -L1 ${OSDEMO} security group rule delete
        ${OSDEMO} security group rule create default --proto icmp --remote-ip "0.0.0.0/0"
        ${OSDEMO} security group rule create default --proto tcp --remote-ip "0.0.0.0/0" --dst-port 22
    else
        echo "Neutron is not installed, skip modifying default security groups."
    fi
}


function run_default {
    reset_os_vars
    patch_system
    allow_wan
    add_keypair
    add_dns
#    add_heat_net
}

if [ $# -eq 0 ]; then
    run_default
    exit $?
fi

while [[ $# > 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            echo -e "Supported options: patch wan key dns secgroup heatnet\nDefault - all the above"
            exit 1
        ;;
        patch)
            patch_system
            shift # past argument
        ;;
        wan)
            allow_wan
            shift # past argument
        ;;
        key)
            add_keypair
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
