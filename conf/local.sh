#! /usr/bin/env bash
DEMO="--os-cloud devstack"
ADMIN="--os-cloud devstack-admin"
CATALOG=`openstack ${ADMIN} catalog list -f value -c Name`

function has_services {
    services=$@
    for service in ${services}; do
        grep -q ${service} <<<${CATALOG} || return 1
    done
    return 0
}

function clean_pkgs {
    sudo -H pip uninstall -y flake8-docstrings
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
        openstack ${DEMO} keypair create demo --public-key $HOME/.ssh/id_rsa.pub
    else
        echo "Nova is not installed, skip adding keypair"
    fi
}

function add_dns {
    if has_services neutron; then
        echo "Adding Google DNS to demo tenant private subnets..."
        # NOTE: openstackclient has no support for neutron subnet CLI for now,
        #       resorting to neutronclient
        dnsserver4=8.8.8.8
        subnet4=$(neutron ${DEMO} subnet-list -f value | grep private-subnet | grep -v ipv6-private-subnet | awk '{print $1}')
        neutron ${DEMO} subnet-update $subnet4 --dns-nameserver $dnsserver4
        neutron ${DEMO} subnet-show $subnet4
        subnet6=$(neutron ${DEMO} subnet-list -f value | grep ipv6-private-subnet | awk '{print $1}')
        if [ -n "${subnet6}" ]; then
            dnsserver6="2001:4860:4860::8888"
            neutron ${DEMO} subnet-update $subnet6 --dns-nameserver $dnsserver6
            neutron ${DEMO} subnet-show $subnet6
        fi
    else
        echo "Neutron is not installed, skip adding DNS."
    fi
}

function add_heat_net {
    if has_services heat neutron; then
        echo "Adding subnet for heat tests..."
        # NOTE: openstackclient has no support for neutron subnet, port and routers CLI for now,
        #       resorting to neutronclient
        PUB_SUBNET_ID=$(neutron ${ADMIN} subnet-list | grep ' public-subnet ' | awk '{split($0,a,"|"); print a[2]}')
        ROUTER_GW_IP=$(neutron ${ADMIN} port-list -c fixed_ips -c device_owner | grep router_gateway | awk -F '"' -v subnet_id="${PUB_SUBNET_ID//[[:space:]]/}" '$4 == subnet_id { print $8; }')

        # create a heat specific private network (default 'private' network has ipv6 subnet)
        HEAT_PRIVATE_SUBNET_CIDR=10.0.5.0/24
        neutron ${DEMO} net-create heat-net
        neutron ${DEMO} subnet-create --name heat-subnet heat-net $HEAT_PRIVATE_SUBNET_CIDR
        neutron ${DEMO} router-interface-add router1 heat-subnet
        sudo route add -net $HEAT_PRIVATE_SUBNET_CIDR gw $ROUTER_GW_IP
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
        openstack ${DEMO} security group rule list default -f value -c ID | xargs -L1 openstack ${DEMO} security group rule delete
        openstack ${DEMO} security group rule create default --proto icmp --src-ip "0.0.0.0/0"
        openstack ${DEMO} security group rule create default --proto tcp --src-ip "0.0.0.0/0" --dst-port 22
    else
        echo "Neutron is not installed, skip modifying default security groups."
    fi
}

function rename_cirros {
    if has_services glance; then
        echo "Renaming cirros image..."
        read -r -a image <<< `openstack ${ADMIN} image list -f value -c ID -c Name | grep "cirros-.*-disk"`
        if [ -n "image[0]" ]; then
            openstack ${ADMIN} image set ${image[0]} --name cirros --property description=${image[1]}
            openstack ${ADMIN} image show ${image[0]}
        fi
    else
        echo "Glance is not installed, skip renaming Cirros image."
    fi
}

function add_awslb_image {
    if has_services heat glance; then
        echo "Uploading Fedora 21 cloud image to glance"
        AWS_LB_IMAGE_NAME=Fedora-Cloud-Base-20141203-21.x86_64
        AWS_LB_IMAGE_URL="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/${AWS_LB_IMAGE_NAME}.qcow2"
        curl -L ${AWS_LB_IMAGE_URL} | openstack ${ADMIN} image create --public --disk-format qcow2  --container-format bare ${AWS_LB_IMAGE_NAME}
    else
        echo "Heat or Glance not installed, skip adding base image for AWS LoadBalancer."
    fi
}

function run_default {
    clean_pkgs
    allow_wan
    add_keypair
    rename_cirros
    secgroup
    add_dns
    add_heat_net
}

if [ $# -eq 0 ]; then
    run_default
    exit 0
fi

while [[ $# > 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            echo -e "Supported options: clean wan key dns secgroup heatnet cirros awslb\nDefault - all the above except awslb"
            exit 0
        ;;
        clean)
            clean_pkgs
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
