import argparse
# from concurrent import futures
import logging
import sys
import time

import futurist
import futurist.waiters
import openstack

PROGRAM_NAME = "port-churn"
LOG = logging.getLogger(PROGRAM_NAME)


def setup():
    parser = argparse.ArgumentParser(
        prog=PROGRAM_NAME,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Attach/detach instance ports en masse in parallel."
    )
    parser.add_argument("server",
                        help="name or id of server to churn ports on")
    parser.add_argument("--workers", type=int, default=2,
                        help="number of paralel workers")
    parser.add_argument("--repeats", type=int, default=1,
                        help="number of attach-detach repeats in each worker")
    parser.add_argument("--interval", type=float, default=0.1,
                        help="pause between API calls, 0 means disabled")
    parser.add_argument(
        "--os-cloud", default=None,
        help="cloud name from clouds.yaml, defaults to OS_CLOUD env var")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    openstack.enable_logging()
    return args


def port_churn(
        index: int,
        name: str,
        cloud_name: str,
        server_id: str,
        repeats: int = 1,
        interval: float | int = 0.1,
):
    CIDR = "10.10.10.0/24"
    IP = f"10.10.10.{10 + index}"
    cloud = openstack.connect(cloud=cloud_name)
    server = cloud.get_server(name_or_id=server_id, bare=True)
    network = None
    subnet = None
    port = None
    all_success = True
    try:
        network = cloud.create_network(name)
        subnet = cloud.create_subnet(name, subnet_name=name, cidr=CIDR)
        port = cloud.create_port(
            network.id, name=name,
            fixed_ips=[dict(subnet_id=subnet.id, ip_address=IP),])
        for n in range(repeats):
            iface = None
            try:
                if n != 0 and interval:
                    time.sleep(interval)
                iface = cloud.compute.create_server_interface(
                    port_id=port.id, server=server.id)
                if interval:
                    time.sleep(interval)
                cloud.compute.delete_server_interface(iface)
                iface = None
            except Exception as e:
                all_success = False
                LOG.error(e)
                if iface:
                    cloud.compute.delete_server_interface(iface)
                continue
    except Exception as e:
        all_success = False
        LOG.error(e)
    finally:
        if port:
            cloud.delete_port(port.id)
        if subnet:
            cloud.delete_subnet(subnet.id)
        if network:
            cloud.delete_network(network.id)
    return all_success


def main():
    args = setup()

    with futurist.ProcessPoolExecutor(max_workers=args.workers) as pool:
        res = []
        for i in range(args.workers):
            name = f"{PROGRAM_NAME}-{i + 1}"
            LOG.info(f"starting worker {i}")
            res.append(
                pool.submit(
                    port_churn,
                    i,
                    name,
                    args.os_cloud,
                    args.server,
                    args.repeats,
                    args.interval,
                )
            )
        done, not_done = futurist.waiters.wait_for_all(res)
        if not_done or not all(r.result() for r in done):
            sys.exit(1)

if __name__ == "__main__":
    main()
