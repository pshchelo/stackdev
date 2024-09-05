#!/opt/stack/data/venv/bin/python3
import argparse
import binascii
from oslo_concurrency import processutils
import openstack

parser = argparse.ArgumentParser(
    prog="cryptcreate",
    description="Re-creates the process Nova uses to create encrypted LVM",
)

parser.add_argument("secret_id", help="Secret id in Barbican to fetch")
parser.add_argument("lv", help="Logical volume to encrypt")
parser.add_argument(
    "--vg",
    default="stack-volumes-default",
    help="Logical volume group the logical volume belongs to",
)
parser.add_argument(
    "--cloud",
    default="devstack-admin",
    help="Cloud-config cloud name to use for Barbican access",
)
parser.add_argument(
    "--cipher", default="aes-xts-plain64", help="Cipher to use for encryption"
)
parser.add_argument(
    "--key-size",
    type=int,
    default=256,
    help="Key size used for encryption, must coinside with "
    "the secret size in Barbican",
)
args = parser.parse_args()

# secret_id = "1847ff2e-f785-4782-84b3-1d7fa6b312c8"
# lvname = "f0a7a6eb-8ced-4f1b-9e2b-eaf66db42752_disk.eph0"

cloud = openstack.connect(cloud=args.cloud)
secret = cloud.key_manager.get_secret(args.secret_id)
payload = secret.payload.encode("Windows-1251")
key = binascii.hexlify(payload).decode("utf-8")

cmd = (
    "cryptsetup",
    "create",
    f"{args.lv}-dmcrypt",
    f"/dev/{args.vg}/{args.lv}",
    f"--cipher={args.cipher}",
    f"--key-size={args.key_size}",
    "--key-file=-",
)

print(f"Encrypting volume {args.lv} with key {key} using command:")
print(" ".join(cmd))
processutils.execute(*cmd, process_input=key)
