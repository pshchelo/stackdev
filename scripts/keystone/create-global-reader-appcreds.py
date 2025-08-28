import openstack
cloud = openstack.connect()
access_rules = [
    dict(method="GET", path="/**", service=service["type"])
    for service in cloud.service_catalog
]
app_creds = cloud.identity.create_application_credential(
    user=cloud.session.get_user_id(),
    name="global-reader",
    description="can access any GET HTTP API with admin role",
    roles = [{"name": "admin"}],
    access_rules=access_rules,
    unrestricted=False,
)
clouds_yaml_entry = f"""
clouds:
  global-reader:
    auth_type: v3applicationcredential
    identity_api_version: "3"
    auth:
      auth_url: {cloud.session.auth.auth_url}
      application_credential_id: {app_creds.id}
      application_credential_secret: {app_creds.secret}
"""
print(clouds_yaml_entry)
