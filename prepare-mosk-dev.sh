#!/usr/bin/env bash
ko="kubectl -n openstack exec -ti deploy/keystone-client -c keystone-client -- openstack"

# Need this role to use Barbican and encrypted storage for instances and volumes
$ko role create --or-show creator
# sandbox project to use w/o admin privileges
demo_project=$($ko project create demo --domain Default -f value -c id --or-show)

# separate admin user - not auto-rotated, with stable name and password,
# to be used from outside
$ko user create superadmin --domain Default --password superadmin
$ko role add admin --user superadmin --user-domain Default --project admin --project-domain Default
$ko role add admin --user superadmin --user-domain Default --domain Default
$ko role add admin --user superadmin --user-domain Default --system all
# custom MOSK role
$ko role add global-secret-decoder --user superadmin --user-domain Default --project admin --project-domain Default
$ko role add global-secret-decoder --user superadmin --user-domain Default --system all

# sandbox user to use w/o admin priveleges
demo_user=$($ko user create demo --domain Default --password demo -f value -c id --or-show)
$ko role add member --user demo --user-domain Default --project demo --project-domain Default
$ko role add creator --user demo --user-domain Default --project demo --project-domain Default

# another sandbox user to use w/o admin privileges
$ko user create alt-demo --domain Default --password alt-demo
$ko role add member --user alt-demo --user-domain Default --project demo --project-domain Default

# readonly user
$ko user create viewer --domain Default --password viewer
$ko role add reader --user viewer --user-domain Default --project admin --project-domain Default
$ko role add reader --user viewer --user-domain Default --project demo --project-domain Default
$ko role add reader --user viewer --user-domain Default --system all

# Minimal flavor for cirros
$ko flavor create m1.nano --ram 128 --disk 1 --vcpus 1

# TODO: needs testing
#n_id=$($ko network create demo --project $demo_project -f value -c id)
#s_id=$($ko subnet create demo --network $n_id --subnet-range 10.20.30.0/24 --project $demo_project -f value -c id)
#r_id=$($ko router create demo --external-gateway public --project $demo_project -f value -c id)
#$ko router add subnet $r_id $s_id --project $demo_project
#$ko security group create demo --project $demo_project
#$ko security group rule create demo --ingress --protocol tcp --dst-port 22 --description SSH --project $demo_project
# FIXME how to pass that to container?
#kubectl -n openstack cp ~/.ssh/pub/aio_rsa.pub deploy/keystone-client:/tmp/pubkey
#$ko keypair create demo --public-key /tmp/pubkey --user $demo_user
