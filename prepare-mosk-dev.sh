ko="kubectl -n openstack exec -ti deploy/keystone-client -c keystone-client -- openstack"

admin_name=$(kubectl -n openstack get secret keystone-os-clouds -ojsonpath='{.data.clouds\.yaml}' | base64 -d | yq -r .clouds.admin.auth.username)
admin_pass=$(kubectl -n openstack get secret keystone-os-clouds -ojsonpath='{.data.clouds\.yaml}' | base64 -d | yq -r .clouds.admin.auth.password)
echo "Admin username is: $admin_name"
echo "Admin password is: $admin_pass"
echo "Writing secure.yaml file for mosk-dev-admin cloud"
cat > secure.yaml << EOF
clouds:
  mosk-dev-admin:
    auth:
      username: $admin_name
      password: $admin_pass
EOF

# Need this role to use Barbican and encrypted storage for instances and volumes
$ko role create --or-show creator
# sandbox project to use w/o admin privileges
$ko project create demo --domain Default

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
