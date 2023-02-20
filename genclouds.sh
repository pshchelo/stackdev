#!/usr/bin/env sh
# generate clouds.yaml with admin account for the test MOS env
mkdir -p ~/.config/openstack
cat > ~/.config/openstack/clouds.yaml << EOF
clouds:
  admin:
    auth:
      auth_url: https://keystone.it.just.works
      username: $(kubectl -n openstack get secret keystone-os-clouds -ojsonpath='{.data.clouds\.yaml}' | base64 -d | yq -r .clouds.admin.auth.username)
      password: $(kubectl -n openstack get secret keystone-os-clouds -ojsonpath='{.data.clouds\.yaml}' | base64 -d | yq -r .clouds.admin.auth.password)
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    insecure: True
    identity_api_version: 3
EOF
