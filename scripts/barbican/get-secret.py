import argparse
import binascii

import openstack
from barbicanclient import client as bclient

parser = argparse.ArgumentParser(
    description="Fetch Barbican secret payload for ephemeral encryption "
                "in the format suitable for dm-crypt key passed over stdin. "
                "Uses either openstacksdk or barbicanclient (default)."
)
parser.add_argument("secret_id", help="ID of the Barbican secret")
parser.add_argument("--client",
                    choices=["sdk", "barbican"],
                    default="barbican",
                    help="Which API client to use. "
                         "OpenStackSDK is always required for auth")
args = parser.parse_args()

cloud = openstack.connect()

if args.client == "barbican":
    # NOTE: payload from barbicanclient is BYTES (requests.Response.content),
    # or decoded UTF-8 text for secrets with text/plain content type
    barbican = bclient.Client(session=cloud.session)
    secret = barbican.secrets.get(args.secret_id)
    payload = secret.payload
else:
    # NOTE: payload from SDK is currently always STR (requests.Response.text),
    # decoded from bytes as whatever was autodetected by `chardet`,
    # which could be anything for a random secret data.
    # Do not use SDK for non-text/plain secrets for now,
    # need this patch first
    # https://review.opendev.org/c/openstack/openstacksdk/+/928151
    secret = cloud.key_manager.get_secret(args.secret_id)
    # to get bytes, need to encode back
    payload = secret.payload.encode("Windows-1251")

dmcrypt_secret = binascii.hexlify(payload).decode("utf-8")
print(dmcrypt_secret, end='')
