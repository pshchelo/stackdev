import argparse
import configparser
import time

from ovs.db import idl
from ovsdbapp.backend.ovs_idl import connection
from ovsdbapp.backend.ovs_idl import idlutils
from ovsdbapp.schema.ovn_northbound import impl_idl


class OvsLock():
    def __init__(self, api, name):
        self.idl = api.idl
        self.lock_name = name

    def __enter__(self):
        print(f"Trying to acuire lock {self.lock_name}")
        self.idl.set_lock(self.lock_name)
        for i in range(5):
            time.sleep(0.1)
            print(f"Check if lock {self.lock_name} is acquired")
            if api.idl.has_lock:
                print(f"Lock {self.lock_name} is acquired")
                break
        else:
            if self.idl.is_lock_contended:
                raise Exception(f"Lock {self.lock_name} is contended")
            else:
                raise Exception(f"Failed to acquire lock {self.lock_name}")
        return self

    def __exit__(self, *exc_details):
        print(f"Releasing lock {self.lock_name}")
        self.idl.set_lock(None)
        print("Check if lock is released")
        assert not self.idl.has_lock
        assert not self.idl.is_lock_contended


def get_connection_from_config(config_file):
    config = configparser.ConfigParser()
    config.read(config_file)
    return config["ovn"]["ovn_nb_connection"]


def setup():
    parser = argparse.ArgumentParser(
        prog="ovsdbnb",
        description="Minimal python client for OVN Northbound DB",
    )
    parser.add_argument(
        "-c", "--connection",
        help="Connection string to OVN NB",
    )
    parser.add_argument(
        "-f", "--config-file",
        default="/tmp/pod-shared/neutron-ovn.ini",
        help="Neutron config file to read OVN NB connection string from",
    )
    parser.add_argument(
        "-t", "--test",
        action="store_true",
        default=False, help="run locking test"
    )
    parser.add_argument(
        "--no-leader-only",
        action="store_false",
        dest="leader_only",
        default=True,
        help="Do not require connection to the leader",
    )
    args = parser.parse_args()
    if args.connection:
        nb_remote = args.connection
    elif args.config_file:
        nb_remote = get_connection_from_config(args.config_file)
    else:
        raise Exception("No connection string or config file provided")

    return nb_remote, args


def make_api(remote, schema_name, leader_only=True):
    schema_helper = idlutils.get_schema_helper(remote, schema_name)
    schema_helper.register_all()
    nb_idl = idl.Idl(remote, schema_helper, leader_only=leader_only)
    conn = connection.Connection(idl=nb_idl, timeout=60)
    return impl_idl.OvnNbApiIdlImpl(conn)


def make_nb_api(remote, args):
    return make_api(remote, "OVN_Northbound", leader_only=args.leader_only)


def test_locking(api, lock_name="testovslock", block=15):
    with OvsLock(api, lock_name):
        print(f"Lock {lock_name} was acquired, blocking for {block}s")
        time.sleep(block)


if __name__ == "__main__":
    remote, args = setup()
    api = make_nb_api(remote, args)
    if args.test:
        test_locking(api)
