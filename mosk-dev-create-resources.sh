#!/bin/bash
# to be run in MOSK's keystone-client pod
export OS_CLOUD=admin-system
# Need this role to use Barbican and encrypted storage for instances and volumes
openstack role create --or-show creator
# sandbox project to use w/o admin privileges
demo_project=$(openstack project create demo --domain Default -f value -c id --or-show)

# separate admin user - not auto-rotated, with stable name and password,
# to be used from outside
openstack user create superadmin --domain Default --password superadmin --or-show
openstack role add admin --user superadmin --user-domain Default --project admin --project-domain Default
openstack role add admin --user superadmin --user-domain Default --domain Default
openstack role add admin --user superadmin --user-domain Default --system all
# custom MOSK role
openstack role add global-secret-decoder --user superadmin --user-domain Default --project admin --project-domain Default
openstack role add global-secret-decoder --user superadmin --user-domain Default --system all

# sandbox user to use w/o admin priveleges
demo_user=$(openstack user create demo --domain Default --password demo -f value -c id --or-show)
openstack role add member --user demo --user-domain Default --project demo --project-domain Default
openstack role add creator --user demo --user-domain Default --project demo --project-domain Default

# another sandbox user to use w/o admin privileges
openstack user create alt-demo --domain Default --password alt-demo --or-show
openstack role add member --user alt-demo --user-domain Default --project demo --project-domain Default

# readonly user
openstack user create viewer --domain Default --password viewer
openstack role add reader --user viewer --user-domain Default --project admin --project-domain Default
openstack role add reader --user viewer --user-domain Default --project demo --project-domain Default
openstack role add reader --user viewer --user-domain Default --system all

export OS_CLOUD=admin
# Minimal flavor for cirros
openstack flavor create m1.nano --ram 128 --disk 1 --vcpus 1
# network, subnet, router, secgroup for demo project
n_id=$(openstack network create demo --project $demo_project -f value -c id)
s_id=$(openstack subnet create demo --network $n_id --subnet-range 10.20.30.0/24 --project $demo_project -f value -c id)
r_id=$(openstack router create demo --project $demo_project -f value -c id)
openstack router set $r_id --external-gateway public
openstack router add subnet $r_id $s_id
openstack security group create demo --project $demo_project
openstack security group rule create demo --ingress --protocol icmp --description PING --project $demo_project
openstack security group rule create demo --ingress --protocol tcp --dst-port 22 --description SSH --project $demo_project
openstack security group rule create demo --ingress --protocol tcp --dst-port 80 --description HTPP --project $demo_project
# keypair for demo user
if [ -f /tmp/pubkey ]; then
    openstack keypair create demo --public-key /tmp/pubkey --user $demo_user
    rm /tmp/pubkey
fi
