#!/usr/bin/env sh
# generate clouds.yaml with admin account for the test MOS env
mkdir -p ~/.config/openstack
cat > ~/.config/openstack/clouds.yaml << EOF
clouds:
  admin:
    auth:
      auth_url: https://keystone.it.just.works
      username: admin
      password: $(kubectl -n openstack get secret keystone-keystone-admin -ojson | jq -r .data.password | base64 -d)
      project_name: admin
      user_domain_name: Default
      project_domain_name: Default
    insecure: True
    identity_api_version: 3
EOF
