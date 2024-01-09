kubectl -n openstack get osdpl osh-dev -oyaml > deployed.osdpl.yaml
cp deployed.osdpl.yaml osdpl.yaml
# mcc-deployed envs have the helmbundle for the operator in the mgmt cluster
if kubectl -n osh-system get helmbundles.lcm.mirantis.com openstack-operator ; then
    kubectl -n osh-system get helmbundles.lcm.mirantis.com openstack-operator -oyaml > deployed.osctl.yaml
fi
