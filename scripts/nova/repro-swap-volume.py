import argparse
import openstack
parser = argparse.ArgumentParser(prog="swap-volume")
parser.add_argument("--server", required=True)
parser.add_argument("--old-volume", required=True)
parser.add_argument("--new-volume", required=True)
parser.add_argument("--debug", action="store_true")
parser.add_argument("--os-cloud", default=None)
args = parser.parse_args()
openstack.enable_logging(http_debug=args.debug)
cloud = openstack.connect(cloud=args.os_cloud)
server = cloud.compute.find_server(args.server)
attached_volumes = [vol.id for vol in server.attached_volumes]
old_volume = cloud.block_storage.find_volume(args.old_volume)
new_volume = cloud.block_storage.find_volume(args.new_volume)
assert old_volume.id in attached_volumes, f"volume {args.old_volume} is not attached to server {args.server}"
assert new_volume.id not in attached_volumes, f"volume {args.new_volume} is already attached to server {args.server}"
res = cloud.compute.put(
    f"/servers/{server.id}/os-volume_attachments/{old_volume.id}",
    json={
        "volumeAttachment": {
            "volumeId": new_volume.id
        }
    },
    raise_exc=True
)
