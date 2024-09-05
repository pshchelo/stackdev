import argparse
import binascii

import openstack
try:
    from barbicanclient import client as bclient
except ImportError:
    bclient = None

parser = argparse.ArgumentParser(
    description="Fetch Barbican secret payload for ephemeral encryption "
                "in the format suitable for dm-crypt key passed over stdin. "
                "Uses either openstacksdk (default) or barbicanclient."
)
parser.add_argument("secret_id", help="ID of the Barbican secret")
parser.add_argument("--client", choices=["sdk", "barbican"], default="sdk",
                    help="Which API client to use. "
                         "OpenStackSDK is always required for auth")
args = parser.parse_args()

cloud = openstack.connect()

if args.client == "sdk":
    # NOTE: payload from SDK is STR (requests.Response.text),
    # aparently Windows-1251 encoded as autodetected by `chardet`,
    # at least that was it with simplecrypto backend of Barbican on DevStack
    secret = cloud.key_manager.get_secret(args.secret_id)
    # to get bytes, need to encode back
    payload = secret.payload.encode("Windows-1251")
elif bclient:
    # NOTE: payload from barbicanclient is BYTES (requests.Response.content)
    barbican = bclient.Client(session=cloud.session)
    secret = barbican.secrets.get(args.secret_id)
    payload = secret.payload
else:
    raise ImportError("please install python-barbicanclient")

dmcrypt_secret = binascii.hexlify(payload).decode("utf-8")
print(dmcrypt_secret, end='')
