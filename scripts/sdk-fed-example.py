import os
import openstack

auth_data = {
    "os_auth_type": "v3oidcpassword",
    "os_identity_provider": "keycloak",
    "os_protocol": "mapped",
    "os_openid_scope": "openid",
    "os_password": os.getenv("OS_PASSWORD"),
    "os_project_domain_name": "Default",
    "os_project_name": "admin",
    "os_discovery_endpoint": "https://keycloak.it.just.works/auth/realms/iam/.well-known/openid-configuration",
    "os_auth_url": "https://keystone.it.just.works/v3",
    "os_insecure": True,
    "os_client_secret": "NotNeeded",
    "os_client_id": "os",
    "os_username": os.getenv("OS_USERNAME"),
    "os_interface": "public",
    "os_endpoint_type": "public",
    "api_timeout": 60,
}

cloud = openstack.connect(load_yaml_config=False, **auth_data)
print(list(cloud.compute.flavors()))
