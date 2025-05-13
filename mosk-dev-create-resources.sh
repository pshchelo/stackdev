#!/usr/bin/env bash
set -e
RED='\033[0;31m'
NOC='\033[0m'
min_osc_version="5.8.0" # can create router already with external gateway
local_osc_version=$(openstack --version | awk '{print $2}')
if echo -e "${local_osc_version}\n${min_osc_version}" | sort -V -C ; then
    echo "Need local openstack client ${min_osc_version} or newer, but have ${RED}${local_osc_version}${NOC}"
    exit 1
fi

echo "resolving keystone-client pod name"
pod=$(kubectl -n openstack get pod -l application=keystone,component=client -ojsonpath='{.items[0].metadata.name}')
echo "resolving openstackclient version"
# create separate admin user - not auto-rotated, with stable name and password, to be used from outside
# run it from the keystone-client pod using the active admin creds there
# NOTE: using system scope for Keystone ops as it is safest bet when strict admin / new policies are enforced
echo "creating superadmin user"
kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system user create --or-show superadmin --domain Default --password superadmin
kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --project admin --project-domain Default
kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --domain Default

# execute the rest locally using separate admin user created above

# needs access to public OpenStack API of MOSK dev cluster, e.g. sshuttle running
if ! grep -q keystone.it.just.works /etc/hosts; then
    read -r -p "${RED}Start sshuttle and press Enter to continue..${NOC}"
fi

# make superadmin also an admin in system scope
openstack --os-cloud mosk-dev-admin role add admin --user superadmin --user-domain Default --system all
echo "creating required roles"
# this is MOSK-specific role
openstack --os-cloud mosk-dev-admin role create --or-show global-secret-decoder
openstack --os-cloud mosk-dev-admin role add global-secret-decoder --user superadmin --user-domain Default --project admin --project-domain Default
openstack --os-cloud mosk-dev-admin role add global-secret-decoder --user superadmin --user-domain Default --system all
# Need this role to use Barbican and encrypted storage for instances and volumes
openstack --os-cloud mosk-dev-admin role create --or-show creator
# Need this by legacy Octavia policies to be able to create or view load balancers
openstack --os-cloud mosk-dev-admin role create --or-show load-balancer_member
openstack --os-cloud mosk-dev-admin role create --or-show load-balancer_observer
openstack --os-cloud mosk-dev-admin role create --or-show load-balancer_global_observer
# reader is there by default since Rocky, let's create it on Queens too
openstack --os-cloud mosk-dev-admin role create --or-show reader

# sandbox project to use w/o admin privileges
echo "creating sandbox project"
openstack --os-cloud mosk-dev-admin project create --or-show demo --domain Default
# sandbox user to use w/o admin priveleges
echo "creating user demo"
openstack --os-cloud mosk-dev-admin user create --or-show demo --domain Default --password demo
openstack --os-cloud mosk-dev-admin role add member --user demo --user-domain Default --project demo --project-domain Default
openstack --os-cloud mosk-dev-admin role add load-balancer_member --user demo --user-domain Default --project demo --project-domain Default
openstack --os-cloud mosk-dev-admin role add creator --user demo --user-domain Default --project demo --project-domain Default
# another sandbox user to use w/o admin privileges
echo "creating user alt-demo"
openstack --os-cloud mosk-dev-admin user create --or-show alt-demo --domain Default --password alt-demo
openstack --os-cloud mosk-dev-admin role add member --user alt-demo --user-domain Default --project demo --project-domain Default
# readonly user
echo "creating read-only user viewer"
openstack --os-cloud mosk-dev-admin user create viewer --domain Default --password viewer
openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --project admin --project-domain Default
openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --project demo --project-domain Default
openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --system all
openstack --os-cloud mosk-dev-admin role add load-balancer_observer --user viewer --user-domain Default --project demo --project-domain Default
openstack --os-cloud mosk-dev-admin role add load-balancer_global_observer --user viewer --user-domain Default --project admin --project-domain Default

# Minimal flavor for cirros
echo "creating minimal flavor"
openstack --os-cloud mosk-dev-admin flavor create m1.nano --ram 128 --disk 1 --vcpus 1

for name in admin demo; do
    echo "creating network for $name"
    openstack --os-cloud mosk-dev-$name network create $name
    echo "creating subnet for $name"
    openstack --os-cloud mosk-dev-$name subnet create $name --network $name --subnet-range 10.20.30.0/24
    echo "creating router to FIP for $name"
    openstack --os-cloud mosk-dev-$name router create $name --external-gateway public
    openstack --os-cloud mosk-dev-$name router add subnet $name $name

    echo "creating security group with ICMP, TCP:22 and TCP:80 ingress for $name"
    openstack --os-cloud mosk-dev-$name security group create $name
    openstack --os-cloud mosk-dev-$name security group rule create $name --ingress --protocol icmp --description PING
    openstack --os-cloud mosk-dev-$name security group rule create $name --ingress --protocol tcp --dst-port 22 --description SSH
    openstack --os-cloud mosk-dev-$name security group rule create $name --ingress --protocol tcp --dst-port 80 --description HTPP

    echo "creating keypair for $name"
    openstack --os-cloud mosk-dev-$name keypair create $name --public-key "${HOME}/.ssh/pub/aio_rsa.pub"
done
