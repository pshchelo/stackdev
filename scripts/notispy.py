#!/usr/bin/env python3

import argparse
import json
import logging
import time

from oslo_config import cfg
import oslo_messaging

"""
https://docs.openstack.org/oslo.messaging/latest/reference/notification_listener.html
"""

logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
)
LOG = logging.getLogger("notispy")


class NotificationEndpoint(object):
    def _format(self, ctxt, publisher_id, event_type, payload, metadata):
        total = {"event_type": event_type,
                 "publisher_id": publisher_id,
                 "payload": payload,
                 "context": ctxt,
                 "metadata": metadata}
        return json.dumps(total)

    def error(self, *args):
        LOG.error(self._format(*args) + "\n===========")

    def warn(self, *args):
        LOG.warning(self._format(*args) + "\n===========")

    def info(self, *args):
        LOG.info(self._format(*args) + "\n===========")

    def audit(self, *args):
        LOG.info("AUDIT - " + self._format(*args) + "\n===========")

    def sample(self, *args):
        LOG.info("SAMPLE - " + self._format(*args) + "\n===========")

    def debug(self, *args):
        LOG.debug(self._format(*args) + "\n===========")

def main():
    parser = argparse.ArgumentParser("notispy")
    parser.add_argument("--config")
    parser.add_argument("--url")
    parser.add_argument("--topic", action="append", dest="topics")
    parser.add_argument("--pool", default="notispy")
    parser.add_argument("--consume", action="store_true")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--exchange", action="append", dest="exchanges")
    args = parser.parse_args()

    if args.debug:
        LOG.setLevel(logging.DEBUG)
    else:
        LOG.setLevel(logging.INFO)
    LOG.debug(f"{args}")

    if args.config:
        cfg.CONF(["--config-file", args.config])

    cfg.CONF.heartbeat_interval = 5
    cfg.CONF.prog = parser.prog
    cfg.CONF.project = parser.prog

    transport = oslo_messaging.get_notification_transport(
        cfg.CONF, url=args.url)
    topics = args.topics or ["notifications"]
    exchanges = args.exchanges or [None]

    targets = [
        oslo_messaging.Target(exchange=e, topic=t)
        for t in topics
        for e in exchanges

    ]
    LOG.debug(f"Messaging targets are {targets}")

    endpoints = [
        NotificationEndpoint()
    ]

    pool = args.pool
    if args.consume:
        pool = None
    LOG.debug(f"pool is {pool}")
    server = oslo_messaging.get_notification_listener(
        transport,
        targets,
        endpoints,
        executor='threading',
        pool=pool,
    )

    LOG.debug("Starting notispy listener...")
    try:
        server.start()
        LOG.info("Started notispy listener")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        LOG.warning("KeyboardInterrput, exiting...")
        pass
    except Exception:
        LOG.info("%s" % e)
        sys.exit(200)
    finally:
        server.stop()
        server.wait()


if __name__ == "__main__":
    main()
