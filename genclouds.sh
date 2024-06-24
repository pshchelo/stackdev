#!/usr/bin/env sh
# generate clouds.yaml with admin account for the test MOS env
clouds_yaml=$(kubectl -n openstack get secret keystone-os-clouds -ojsonpath='{.data.clouds\.yaml}' | base64 -d)
echo "clouds:
  admin:
    auth:
      auth_url: https://keystone.it.just.works
      username: $(echo  "$clouds_yaml" | yq -r .clouds.admin.auth.username)
      password: $(echo  "$clouds_yaml" | yq -r .clouds.admin.auth.password)
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    insecure: true
    interface: public
    region_name: $(echo  "$clouds_yaml" | yq -r .clouds.admin.region_name)
    identity_api_version: '3'"
#EOF
