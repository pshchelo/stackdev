#!/usr/bin/env bash
# rely on fact that there's ever only one OsDpl object in the MOSK cluster
OSDPL_FILE="osdpl.yaml"
OSCTL_FILE="osctl.yaml"
IMAGES_FILE="images-cm.yaml"
DEPLOYED_OSDPL_FILE="deployed.$OSDPL_FILE"
DEPLOYED_OSCTL_FILE="deployed.$OSCTL_FILE"
DEPLOYED_IMAGES_FILE="deployed.$IMAGES_FILE"
OSDPL_NAME=$(kubectl -n openstack get osdpl \
    -o jsonpath='{.items[].metadata.name}')
kubectl -n openstack get osdpl "$OSDPL_NAME" -oyaml > "$DEPLOYED_OSDPL_FILE"
cat "$DEPLOYED_OSDPL_FILE" | yq -y '{"apiVersion": .apiVersion, "kind": .kind, "metadata": {"name": .metadata.name, "namespace": .metadata.namespace}, "spec": .spec}' > "$OSDPL_FILE"
kubectl -n osh-system get helmbundles.lcm.mirantis.com openstack-operator \
    --ignore-not-found=true -oyaml > "$DEPLOYED_OSCTL_FILE"
if [ -s "$DEPLOYED_OSCTL_FILE" ]; then
    cat "$DEPLOYED_OSCTL_FILE" | yq -y '{"apiVersion": .apiVersion, "kind": .kind, "metadata": {"name": .metadata.name, "namespace": .metadata.namespace}, "spec": .spec}' > "$OSCTL_FILE"
else
    # mcc-deployed envs have the helmbundle for the operator
    # in the mgmt cluster, so ignore not found and delete empty file
    rm "$DEPLOYED_OSCTL_FILE"
fi
# fetch or create a stub for OsDpl artifacts config map
kubectl -n openstack get cm "${OSDPL_NAME}-artifacts" \
    --ignore-not-found -o yaml > "$DEPLOYED_IMAGES_FILE"
if [ -s  "$DEPLOYED_IMAGES_FILE" ]; then
    cp "$DEPLOYED_IMAGES_FILE" "$IMAGES_FILE"
else
    rm "$DEPLOYED_IMAGES_FILE"
    # resolve openstack release
    OS_RELEASE=$(kubectl -n openstack get osdpl "$OSDPL_NAME" \
        -o jsonpath='{.spec.openstack_version}')
    # fill in a stub
    cat > "$IMAGES_FILE" << EOF
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
