#!/usr/bin/env bash
# rely on fact that there's ever only one OsDpl object in the MOSK cluster
OSDPL_NAME=$(kubectl -n openstack get osdpl \
    -o jsonpath='{.items[].metadata.name}')
kubectl -n openstack get osdpl "$OSDPL_NAME" -oyaml > deployed.osdpl.yaml
# TODO: automate cleanup of osdpl yaml
# remove status and all metadata except name and namespace
cp deployed.osdpl.yaml osdpl.yaml
# mcc-deployed envs have the helmbundle for the operator in the mgmt cluster,
# so ignore not found and delete empty file
kubectl -n osh-system get helmbundles.lcm.mirantis.com openstack-operator \
    --ignore-not-found=true -oyaml > deployed.osctl.yaml
if [ ! -s deployed.osctl.yaml ]; then
    rm deployed.osctl.yaml
fi
# fetch or create a stub for OsDpl artifacts config map
kubectl -n openstack get cm "${OSDPL_NAME}-artifacts" \
    --ignore-not-found -o yaml > osdpl-artifacts.yaml
if [ ! -s osdpl-artifacts.yaml ]; then
    # resolve openstack release
    OS_RELEASE=$(kubectl -n openstack get osdpl "$OSDPL_NAME" \
        -o jsonpath='{.spec.openstack_version}')
    # fill in a stub
    cat > osdpl-artifacts.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    openstack.lcm.mirantis.com/watch: "true"
  name: ${OSDPL_NAME}-artifacts
  namespace: openstack
data:
  ${OS_RELEASE}: |
EOF
fi
