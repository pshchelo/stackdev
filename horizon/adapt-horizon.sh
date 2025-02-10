#!/usr/bin/env bash
set -e

horizon_pod=$(kubectl -n openstack get pod -l application=horizon -ocustom-columns=NAME:.metadata.name --no-headers | head -n1)
kubectl -n openstack exec -c horizon "${horizon_pod}" -- tar -chf - /etc/openstack-dashboard | tar -x --strip-components=1 -f -
kubectl -n openstack exec -c horizon "${horizon_pod}" -- tar -chf - /usr/local/share/openstack_dashboard/custom_themes | tar -x --strip-components=4 -f -
mv custom_themes openstack-dashboard/
kubectl -n openstack cp -c horizon "${horizon_pod}:/certs/ca-bundle.pem" openstack-dashboard/ca-bundle.pem
kubectl -n openstack cp -c horizon "${horizon_pod}:/usr/local/share/openstack_dashboard/local/local_settings.py" local_settings.py
cat >> local_settings.py << EOF


# === CHANGES FOR RUNNING LOCALLY ===
DEBUG = True
TEMPLATE_DEBUG = False
COMPRESS_OFFLINE = False
STATIC_ROOT = None
OPENSTACK_KEYSTONE_URL = "https://keystone.it.just.works/v3"
OPENSTACK_ENDPOINT_TYPE = "publicURL"
WEBSSO_INITIAL_CHOICE = "credentials"
ALLOWED_HOSTS = ["*"]
SESSION_ENGINE = 'django.contrib.sessions.backends.file'
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.filebased.FileBasedCache",
        "LOCATION": LOCAL_PATH + "/django_cache",
    }
}
# TODO: test how to make "direct" work, patch CORS in Glance?
HORIZON_IMAGES_UPLOAD_MODE = "legacy"
LOCAL_PATH="${PWD}/openstack-dashboard"
POLICY_FILES_PATH = LOCAL_PATH
OPENSTACK_SSL_CACERT = LOCAL_PATH + "/ca-bundle.pem"
MESSAGES_PATH = LOCAL_PATH + "/motd"
TEMPLATES[0]["DIRS"]= [LOCAL_PATH + "/templates"]
# TODO: handle possible many custom themes, in a loop find all that reference custom_theme, extrach theme path, use with new path
AVAILABLE_THEMES[2] = ("mirantis", "Mirantis", LOCAL_PATH + "/custom_themes/mirantis")
EOF
echo "Copy local_settings.py to openstack_dashboard/local dir of your Horizon repo"
