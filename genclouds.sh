#!/usr/bin/env sh
# generate clouds.yaml with admin account for the test MOS env
# TODO: discover URL from osdpl
URL=${1:-"https://keystone.it.just.works"}
clouds_yaml=$(kubectl -n openstack get secret keystone-os-clouds -ojsonpath='{.data.clouds\.yaml}' | base64 -d)
cat > clouds.yaml << EOF
clouds:
  admin:
    auth:
      auth_url: $URL
      username: $(echo  "$clouds_yaml" | yq -r .clouds.admin.auth.username)
      password: $(echo  "$clouds_yaml" | yq -r .clouds.admin.auth.password)
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    insecure: true
    interface: public
    region_name: $(echo  "$clouds_yaml" | yq -r .clouds.admin.region_name)
    identity_api_version: '3'
EOF
