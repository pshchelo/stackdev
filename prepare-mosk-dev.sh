echo "Admin password is: $(kubectl -n openstack get secret keystone-os-clouds -ojsonpath="{.data['clouds\.yaml']}" | base64 -d | yq -r .clouds.admin.auth.password)"

# Need this role to use Barbican and encrypted storage for instances and volumes
kopenstack role create --or-show creator
# sandbox project to use w/o admin privileges
kopenstack project create demo --domain Default

# sandbox user to use w/o admin priveleges
kopenstack user create demo --domain Default --password demo
kopenstack role add member --user demo --user-domain Default --project demo --project-domain Default
kopenstack role add creator --user demo --user-domain Default --project demo --project-domain Default

# another sandbox user to use w/o admin privileges
kopenstack user create alt-demo --domain Default --password alt-demo
kopenstack role add member --user alt-demo --user-domain Default --project demo --project-domain Default

# Minimal flavor for cirros
kopenstack flavor create m1.nano --ram 128 --disk 1 --vcpus 1


# TODO: change to kopenstack calls using 'demo' project id
# openstack keypair create demo --public-key ~/.ssh/pub/aio_rsa.pub 
# openstack network create demo
# openstack subnet create demo --network demo --subnet-range 10.20.30.0/24
# openstack router create demo --external-gateway public
# openstack router add subnet demo demo
# openstack security group create demo
# openstack security group rule create demo --ingress --protocol tcp --dst-port 22 --description SSH
