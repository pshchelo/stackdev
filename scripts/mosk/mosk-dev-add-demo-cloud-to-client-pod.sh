#!/usr/bin/env bash
pod=$(kubectl -n openstack get pod -l application=keystone,component=client -ojsonpath='{.items[].metadata.name}')
cat << EOF > /tmp/clouds.yaml.snippet.demo

  demo:
    auth:
      auth_url: http://keystone-api.openstack.svc.cluster.local:5000/
      username: demo
      password: demo
      user_domain_name: default
      project_domain_name: default
      project_name: demo
    region_name: CustomRegion
    identity_api_version: '3'
    interface: internal
    endpoint_type: internal
EOF
kubectl -n openstack cp -c keystone-client /tmp/clouds.yaml.snippet.demo "$pod":/tmp/clouds.yaml.snippet.demo
rm /tmp/clouds.yaml.snippet.demo
kubectl -n openstack exec "$pod" -c keystone-client -- cp /etc/openstack/clouds.yaml /tmp/clouds.yaml
kubectl -n openstack exec "$pod" -c keystone-client -- bash -c 'cat /tmp/clouds.yaml.snippet.demo >> /tmp/clouds.yaml'
kubectl -n openstack exec "$pod" -c keystone-client -- rm /tmp/clouds.yaml.snippet.demo
