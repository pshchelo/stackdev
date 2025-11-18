#!/usr/bin/env python3
import argparse
import logging
import pykube

PROG_NAME = "osctl-clean-ns"

logging.basicConfig(level=logging.INFO)

LOG = logging.getLogger(PROG_NAME)

def parse_args():
    parser = argparse.ArgumentParser(
        prog=PROG_NAME, description="Cleanup openstack namespace",
        epilog=("This script will delete all PVC, ConfigMap "
                "and almost all Secrets from provided namespace")
    )
    parser.add_argument("--namespace", default="openstack",
                        help=("Namespace to clean"))
    return parser.parse_args()

def delete_mariadb_pvc(api, namespace):
    for res in pykube.PersistentVolumeClaim.objects(
            api, namespace=namespace).filter(
            selector={"application": "mariadb",
                      "component": "server",
                      "release_group": "openstack-mariadb"
                      }
            ):
        LOG.info(f"deleting {res.namespace}/{res.kind} {res.name}")
        res.delete()

def delete_configmaps(api, namespace):
    for res in pykube.ConfigMap.objects(api, namespace=namespace):
        LOG.info(f"deleting {res.namespace}/{res.kind} {res.name}")
        res.delete()

def delete_secrets(api, namespace):
    for res in pykube.Secret.objects(api, namespace=namespace):
        if res.name.startswith("default"):
            LOG.info(f"Skipping default namespace {res.namespace} Secret "
                     f"{res.name}")
        else:
            LOG.info(f"deleting {res.namespace}/{res.kind} {res.name}")
            res.delete()

def main():
    args = parse_args()
    api = pykube.HTTPClient(pykube.KubeConfig.from_env())
    delete_secrets(api, args.namespace)
    delete_configmaps(api, args.namespace)
    delete_mariadb_pvc(api, args.namespace)


if __name__ == "__main__":
    main()
