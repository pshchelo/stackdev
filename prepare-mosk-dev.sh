#!/usr/bin/env bash
set -ex
# create separate admin user - not auto-rotated, with stable name and password, to be used from outside
# run it from the keystone-client pod using the active admin creds there
# NOTE: using system scope for Keystone ops as it is safest bet when strict admin / new policies are enforced
# TODO: discover somehow OpenStack release, as system scope is not present in Queens
pod=$(kubectl -n openstack get pod -l application=keystone,component=client -ojsonpath='{.items[0].metadata.name}')
kubectl -n openstack exec -ti $pod -c keystone-client -- openstack --os-cloud admin-system user create superadmin --domain Default --password superadmin --or-show
kubectl -n openstack exec -ti $pod -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --project admin --project-domain Default
kubectl -n openstack exec -ti $pod -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --domain Default
kubectl -n openstack exec -ti $pod -c keystone-client -- openstack --os-cloud admin-system role add admin --user superadmin --user-domain Default --system all

# execute the rest locally using separate admin user created above
# needs access to public OpenStack API of MOSK dev cluster, e.g. sshuttle running

# custom MOSK role
openstack --os-cloud mosk-dev-admin role add global-secret-decoder --user superadmin --user-domain Default --project admin --project-domain Default
openstack --os-cloud mosk-dev-admin role add global-secret-decoder --user superadmin --user-domain Default --system all
# Need this role to use Barbican and encrypted storage for instances and volumes
openstack --os-cloud mosk-dev-admin role create --or-show creator
# sandbox project to use w/o admin privileges
openstack --os-cloud mosk-dev-admin project create demo --domain Default --or-show
# sandbox user to use w/o admin priveleges
openstack --os-cloud mosk-dev-admin user create demo --domain Default --password demo --or-show
openstack --os-cloud mosk-dev-admin role add member --user demo --user-domain Default --project demo --project-domain Default
openstack --os-cloud mosk-dev-admin role add creator --user demo --user-domain Default --project demo --project-domain Default
# another sandbox user to use w/o admin privileges
openstack --os-cloud mosk-dev-admin user create alt-demo --domain Default --password alt-demo --or-show
openstack --os-cloud mosk-dev-admin role add member --user alt-demo --user-domain Default --project demo --project-domain Default
# readonly user
openstack --os-cloud mosk-dev-admin user create viewer --domain Default --password viewer
openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --project admin --project-domain Default
openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --project demo --project-domain Default
openstack --os-cloud mosk-dev-admin role add reader --user viewer --user-domain Default --system all
# Minimal flavor for cirros
openstack --os-cloud mosk-dev-admin flavor create m1.nano --ram 128 --disk 1 --vcpus 1

# network, subnet, router, secgroup for demo project
openstack --os-cloud mosk-dev-demo network create demo
openstack --os-cloud mosk-dev-demo subnet create demo --network demo --subnet-range 10.20.30.0/24
openstack --os-cloud mosk-dev-demo router create demo
# NOTE: older OpenStack's (Queens etc) do not allow setting external gateway on the router right during creation
openstack --os-cloud mosk-dev-demo router set demo --external-gateway public
openstack --os-cloud mosk-dev-demo router add subnet demo demo
openstack --os-cloud mosk-dev-demo security group create demo
openstack --os-cloud mosk-dev-demo security group rule create demo --ingress --protocol icmp --description PING
openstack --os-cloud mosk-dev-demo security group rule create demo --ingress --protocol tcp --dst-port 22 --description SSH
openstack --os-cloud mosk-dev-demo security group rule create demo --ingress --protocol tcp --dst-port 80 --description HTPP
# keypair for demo user
openstack --os-cloud mosk-dev-demo keypair create demo --public-key ${HOME}/.ssh/pub/aio_rsa.pub
