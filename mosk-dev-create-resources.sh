#!/usr/bin/env bash
set -e
echo resolving keystone-client pod name
pod=$(kubectl -n openstack get pod -l application=keystone,component=client -ojsonpath='{.items[0].metadata.name}')
echo resolving openstackclient version
osc_version=$(kubectl -n openstack exec "$pod" -c keystone-client -- openstack --version | awk '{print $2}')
# create separate admin user - not auto-rotated, with stable name and password, to be used from outside
# run it from the keystone-client pod using the active admin creds there
# NOTE: using system scope for Keystone ops as it is safest bet when strict admin / new policies are enforced
echo creating superadmin user
kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system user create superadmin --domain Default --password superadmin --or-show
kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --project admin --project-domain Default
kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --domain Default
# openstackclient supports assigning system roles since version 3.16.0/Rocky
if echo -e "3.16.0\n$osc_version" | sort -V -C ; then
    kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --system all
fi

region=$(kubectl -n openstack exec -ti "$pod" -c keystone-client -- openstack endpoint list --service identity --interface public -f value -c Region | tr -d '\r')
# TODO: re-enable when zaqarclient 3.0.1 with this fix
# https://review.opendev.org/c/openstack/python-zaqarclient/+/944605
# is released and installed in MOSK/Epoxy keystone-client container
#export OS_REGION_NAME=$region

# execute the rest locally using separate admin user created above
# needs access to public OpenStack API of MOSK dev cluster, e.g. sshuttle running

if ! grep -q keystone.it.just.works /etc/hosts; then
    read -r -p "Start sshuttle and press Enter to continue.."
fi

# custom MOSK role
echo creating required roles
if openstack --os-cloud mosk-dev-admin role show global-secret-decoder > /dev/null; then
    openstack --os-cloud mosk-dev-admin role add global-secret-decoder --user superadmin --user-domain Default --project admin --project-domain Default
    # openstackclient supports assigning system roles since version 3.16.0/Rocky
    if echo -e "3.16.0\n$osc_version" | sort -V -C; then
        openstack --os-cloud mosk-dev-admin role add global-secret-decoder --user superadmin --user-domain Default --system all
    fi
fi
# Need this role to use Barbican and encrypted storage for instances and volumes
openstack --os-cloud mosk-dev-admin role create --or-show creator
# sandbox project to use w/o admin privileges
echo creating sandbox project
openstack --os-cloud mosk-dev-admin project create demo --domain Default --or-show
# sandbox user to use w/o admin priveleges
echo creating user demo
openstack --os-cloud mosk-dev-admin user create demo --domain Default --password demo --or-show
openstack --os-cloud mosk-dev-admin role add member --user demo --user-domain Default --project demo --project-domain Default
if openstack --os-cloud mosk-dev-admin role show load-balancer_member > /dev/null; then
    openstack --os-cloud mosk-dev-admin role add load-balancer_member --user demo --user-domain Default --project demo --project-domain Default
fi
openstack --os-cloud mosk-dev-admin role add creator --user demo --user-domain Default --project demo --project-domain Default
# another sandbox user to use w/o admin privileges
echo creating user alt-demo
openstack --os-cloud mosk-dev-admin user create alt-demo --domain Default --password alt-demo --or-show
openstack --os-cloud mosk-dev-admin role add member --user alt-demo --user-domain Default --project demo --project-domain Default
# readonly user
echo creating read-only user viewer
openstack --os-cloud mosk-dev-admin user create viewer --domain Default --password viewer
if openstack --os-cloud mosk-dev-admin role show load-balancer_observer > /dev/null; then
    openstack --os-cloud mosk-dev-admin role add load-balancer_observer --user viewer --user-domain Default --project demo --project-domain Default
fi
if openstack --os-cloud mosk-dev-admin role show load-balancer_global_observer > /dev/null; then
    openstack --os-cloud mosk-dev-admin role add load-balancer_global_observer --user viewer --user-domain Default --project admin --project-domain Default
fi
# reader role is present since Rocky, as well as ability to set system scope on openstackclient
if echo -e "3.16.0\n$osc_version" | sort -V -C ; then
    openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --project admin --project-domain Default
    openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --project demo --project-domain Default
    openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --system all
fi
# Minimal flavor for cirros
echo creating minimal flavor
openstack --os-cloud mosk-dev-admin flavor create m1.nano --ram 128 --disk 1 --vcpus 1

for name in admin demo; do
    echo creating network for "$name"
    openstack --os-cloud mosk-dev-$name network create $name
    echo creating subnet for "$name"
    openstack --os-cloud mosk-dev-$name subnet create $name --network $name --subnet-range 10.20.30.0/24
    echo creating router to FIP for "$name"
    openstack --os-cloud mosk-dev-$name router create $name
    # NOTE: older OpenStack's (Queens etc) do not allow setting external gateway on the router right during creation
    openstack --os-cloud mosk-dev-$name router set $name --external-gateway public
    openstack --os-cloud mosk-dev-$name router add subnet $name $name

    echo creating security group with ICMP, TCP:22 and TCP:80 ingress for "$name"
    openstack --os-cloud mosk-dev-$name security group create $name
    openstack --os-cloud mosk-dev-$name security group rule create $name --ingress --protocol icmp --description PING
    openstack --os-cloud mosk-dev-$name security group rule create $name --ingress --protocol tcp --dst-port 22 --description SSH
    openstack --os-cloud mosk-dev-$name security group rule create $name --ingress --protocol tcp --dst-port 80 --description HTPP

    echo creating keypair for "$name"
    openstack --os-cloud mosk-dev-$name keypair create $name --public-key "${HOME}/.ssh/pub/aio_rsa.pub"
done
