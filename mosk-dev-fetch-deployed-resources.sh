kubectl -n osh-system get helmbundles.lcm.mirantis.com openstack-operator -oyaml > deployed.osctl.yaml
kubectl -n openstack get osdpl osh-dev -oyaml > deployed.osdpl.yaml
cp deployed.osdpl.yaml osdpl.yaml
