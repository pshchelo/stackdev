#!/usr/bin/env python3

import argparse
import logging

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
    def info(self, ctxt, publisher_id, event_type, payload, metadata):
        LOG.info("%s %s %s %s %s",
                 ctxt, publisher_id, event_type, payload, metadata)


def main():
    parser = argparse.ArgumentParser("notispy")
    parser.add_argument("--config")
    parser.add_argument("--url")
    parser.add_argument("--topic", default="notifications")
    parser.add_argument("--pool", default="notispy")
    parser.add_argument("--consume", action="store_true")
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()

    if args.debug:
        LOG.setLevel(logging.DEBUG)
    else:
        LOG.setLevel(logging.INFO)

    if args.config:
        cfg.CONF(["--config-file", args.config])

    cfg.CONF.heartbeat_interval = 5
    cfg.CONF.prog = parser.prog
    cfg.CONF.project = parser.prog

    transport = oslo_messaging.get_notification_transport(
        cfg.CONF, url=args.url)
    targets = [
        oslo_messaging.Target(topic=args.topic),
    ]
    endpoints = [
        NotificationEndpoint()
    ]

    server = oslo_messaging.get_notification_listener(
        transport,
        targets,
        endpoints,
        executor='threading',
        pool=None if args.consume else args.pool,
    )

    LOG.debug("Starting notispy server...")
    server.start()
    server.wait()

if __name__ == "__main__":
    main()
