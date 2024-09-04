import binascii
import sys

import openstack
# from barbicanclient import client

if len(sys.argv) < 2:
    sys.exit("Need secret id as first argument")

secret_id = sys.argv[1]

cloud = openstack.connect()

# NOTE: the payload from SDK is STR (requests.Response.text),
# aparently Windows-1251 encoded as autodetected by `chardet`,
# at least that was it with simplecrypto backend of Barbican on DevStack
secret = cloud.key_manager.get_secret(secret_id)
# to get bytes, need to encode back
payload = secret.payload.encode("Windows-1251")

# NOTE: the payload from barbicanclient is BYTES (requests.Response.content)
# barbican = client.Client(session=cloud.session)
# secret = barbican.secrets.get(secret_id)
# payload = secret.payload

dmcrypt_secret = binascii.hexlify(payload).decode("utf-8")
print(dmcrypt_secret, end='')
