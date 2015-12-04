#! /usr/bin/env bash
CREDS=/opt/stack/devstack/openrc
OSCLI="openstack --os-cloud devstack"
OSCLI_ADMIN="openstack --os-cloud devstack-admin"
CATALOG=`${OSCLI_ADMIN} catalog list -f value -c Name`

function has_services {
    services=$@
    for service in ${services}; do
        grep -q ${service} <<<${CATALOG} || return 1
    done
    return 0
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
        echo "Adding demo keypair..."
        ${OSCLI} keypair create demo --public-key $HOME/.ssh/git_rsa.pub
    fi
}

function add_dns {
    if has_services neutron; then
        echo "Adding Google DNS to demo tenant private subnets..."
        # NOTE: openstackclient has no support for neutron subnet CLI for now,
        #       resorting to neutronclient
        source $CREDS demo demo
        dnsserver4=8.8.8.8
        subnet4=`neutron subnet-list -f value | grep private-subnet | grep -v ipv6-private-subnet | awk '{print $1}'`
        neutron subnet-update $subnet4 --dns-nameserver $dnsserver4
        neutron subnet-show $subnet4
        subnet6=`neutron subnet-list -f value | grep ipv6-private-subnet | awk '{print $1}'`
        if [ -n "${subnet6}" ]; then
            dnsserver6="2001:4860:4860::8888"
            neutron subnet-update $subnet6 --dns-nameserver $dnsserver6
            neutron subnet-show $subnet6
        fi
    fi
}

function add_heat_net {
    #FIXME: check does not seem to work reliably
    if has_services heat neutron; then
        echo "Adding subnet for heat tests..."
        # NOTE: openstackclient has no support for neutron subnet, port and routers CLI for now,
        #       resorting to neutronclient
        source $CREDS admin admin
        PUB_SUBNET_ID=`neutron subnet-list | grep ' public-subnet ' | awk '{split($0,a,"|"); print a[2]}'`
        ROUTER_GW_IP=`neutron port-list -c fixed_ips -c device_owner | grep router_gateway | awk -F '"' -v subnet_id="${PUB_SUBNET_ID//[[:space:]]/}" '$4 == subnet_id { print $8; }'`

        # create a heat specific private network (default 'private' network has ipv6 subnet)
        source $CREDS demo demo
        HEAT_PRIVATE_SUBNET_CIDR=10.0.5.0/24
        neutron net-create heat-net
        neutron subnet-create --name heat-subnet heat-net $HEAT_PRIVATE_SUBNET_CIDR
        neutron router-interface-add router1 heat-subnet
        sudo route add -net $HEAT_PRIVATE_SUBNET_CIDR gw $ROUTER_GW_IP
    fi
}

function secgroup {
    if has_services neutron; then
        echo "Adding ingress ICMP and SSH to default security group..."
        # FIXME: use openstackclient for secgroup modifications
        source $CREDS demo demo
        neutron security-group-rule-list -f csv -c id -c security_group -c direction | grep 'default.*ingress' | awk -F "," '{print $1}' | xargs -L1 neutron security-group-rule-delete
        neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol ICMP
        neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol TCP --port-range-min 22 --port-range-max 22
    fi
}

function rename_cirros {
    if has_services glance; then
        echo "Renaming cirros image..."
        read -r -a image <<< `${OSCLI_ADMIN} image list -f value -c ID -c Name | grep "cirros-.*-disk"`
        ${OSCLI_ADMIN} image set ${image[0]} --name cirros --property description=${image[1]}
        ${OSCLI_ADMIN} image show ${image[0]}
    fi
}

function add_awslb_image {
    if has_services heat glance; then
        echo "Uploading Fedora 21 cloud image to glance"
        AWS_LB_IMAGE_NAME=Fedora-Cloud-Base-20141203-21.x86_64
        AWS_LB_IMAGE_URL="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/${AWS_LB_IMAGE_NAME}.qcow2"
        curl -L ${AWS_LB_IMAGE_URL} | ${OSCLI_ADMIN} image create --public --disk-format qcow2  --container-format bare ${AWS_LB_IMAGE_NAME}
    fi
}

function run_default {
    allow_wan
    add_keypair
    add_dns
    add_heat_net
    secgroup
    rename_cirros
}

if [ $# -eq 0 ]; then
    run_default
    exit 0
fi

while [[ $# > 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            echo -e "Supported options: wan key dns secgroup heatnet cirros awslb\nDefault - all the above except awslb"
            exit 0
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
        cirros)
            rename_cirros
            shift
        ;;
        awslb)
            add_awslb_image
        ;;
        *)
            echo -e "Unregognized option $key\nRun with -h to see available options"
            exit 1
        ;;
    esac
    shift # past argument or value
done
