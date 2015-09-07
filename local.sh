#! /usr/bin/env bash
# common functions and paths
TOP_DIR=$(cd $(dirname "$0") && pwd)
CREDS=$TOP_DIR/openrc
source $TOP_DIR/functions
source $TOP_DIR/stackrc
#DEST=${DEST:-/opt/stack}

allow_wan() {
    WAN_SET=$(sudo iptables -t nat -L | grep "MASQUERADE.*all.*anywhere.*anywhere")
    if [ -z "$WAN_SET" ]; then
        echo "Allowing WAN access for VMs..."
        sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    else
        echo "WAN access is already allowed."
    fi
}

add_keypair() {
    if is_service_enabled nova; then
        echo "Adding demo keypair..."
        source $CREDS demo demo
        nova keypair-add demo --pub_key $HOME/.ssh/git_rsa.pub
        nova keypair-list
    fi
}

add_dns() {
    if is_service_enabled neutron; then
        echo "Adding Google DNS to demo tenant private subnets..."
        source $CREDS demo demo
        dnsserver4=8.8.8.8
        subnet4=$(neutron subnet-list | grep " private-subnet" | awk '{print $2}')
        neutron subnet-update $subnet4 --dns-nameserver $dnsserver4
        neutron subnet-show $subnet4
        # as of after-Kilo devstack creates two subnets, IPv4 and IPv6
        # FIXME: change this to !='stable/kilo" after Liberty release
        # and EOL of stable/juno
        if [ ${NEUTRON_BRANCH} == "master" ]; then
            dnsserver6="2001:4860:4860::8888"
            subnet6=$(neutron subnet-list | grep "ipv6-private-subnet" | awk '{print $2}')
            neutron subnet-update $subnet6 --dns-nameserver $dnsserver6
            neutron subnet-show $subnet6
        fi
    fi
}

add_heat_net() {
    if is_service_enabled neutron && is_service_enabled heat; then
        echo "Adding subnet for heat tests..."
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
    else
        echo "either Heat or Neutron are not enabled"
    fi

}
secgroup() {
    if is_service_enabled neutron; then
        echo "Adding ingress ICMP and SSH to default security group..."
        source $CREDS demo demo
        neutron security-group-rule-list -f csv -c id -c security_group -c direction | grep 'default.*ingress' | awk -F "," '{print $1}' | xargs -L1 neutron security-group-rule-delete
        neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol ICMP
        neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol TCP --port-range-min 22 --port-range-max 22
    fi
}

rename_cirros() {
    if is_service_enabled glance; then
        echo "Renaming cirros image..."
        source $CREDS admin admin
        IFS=';' read -a image_line <<< $(glance image-list | grep "cirros-.*-disk" | awk '{print $2";"$4'})
        glance image-update ${image_line[0]} --name cirros --property description=${image_line[1]}
    fi
}

add_awslb_image() {
    if is_service_enabled glance; then
        echo "Uploading Fedora 21 cloud image to glance"
        source $CREDS admin admin
        AWS_LB_IMAGE_NAME=Fedora-Cloud-Base-20141203-21.x86_64
        AWS_LB_IMAGE_URL="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/${AWS_LB_IMAGE_NAME}.qcow2"
        curl -L ${AWS_LB_IMAGE_URL} | glance image-create --visibility public --disk-format qcow2  --container-format bare --name ${AWS_LB_IMAGE_NAME}
    fi
}

run_default() {
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
