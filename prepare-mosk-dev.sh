ko="kubectl -n openstack exec -ti deploy/keystone-client -c keystone-client -- openstack"

# Need this role to use Barbican and encrypted storage for instances and volumes
$ko role create --or-show creator
# sandbox project to use w/o admin privileges
$ko project create demo --domain Default

# separate admin user - not auto-rotated, with stable name and password,
# to be used from outside
$ko user create superadmin --domain Default --password superadmin
$ko role add admin --user superadmin --user-domain Default --project admin --project-domain Default
$ko role add admin --user superadmin --user-domain Default --domain Default
$ko role add admin --user superadmin --user-domain Default --system all
# custom MOSK role
$ko role add global-secret-decoder --user superadmin --user-domain Default --project admin --project-domain Default

# sandbox user to use w/o admin priveleges
$ko user create demo --domain Default --password demo
$ko role add member --user demo --user-domain Default --project demo --project-domain Default
$ko role add creator --user demo --user-domain Default --project demo --project-domain Default

# another sandbox user to use w/o admin privileges
$ko user create alt-demo --domain Default --password alt-demo
$ko role add member --user alt-demo --user-domain Default --project demo --project-domain Default

# Minimal flavor for cirros
$ko flavor create m1.nano --ram 128 --disk 1 --vcpus 1

# TODO: change to ko calls using 'demo' project id
# openstack keypair create demo --public-key ~/.ssh/pub/aio_rsa.pub
# openstack network create demo
# openstack subnet create demo --network demo --subnet-range 10.20.30.0/24
# openstack router create demo --external-gateway public
# openstack router add subnet demo demo
# openstack security group create demo
# openstack security group rule create demo --ingress --protocol tcp --dst-port 22 --description SSH
