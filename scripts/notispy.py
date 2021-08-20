# import eventlet
# eventlet.monkey_patch()

import logging

from oslo_config import cfg
import oslo_messaging

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger("notispy")


class NotificationEndpoint(object):
    def info(self, ctxt, publisher_id, event_type, payload, metadata):
        LOG.info("%s %s %s %s %s",
                 ctxt, publisher_id, event_type, payload, metadata)


transport = oslo_messaging.get_notification_transport(
    cfg.CONF, url="rabbit://stackrabbit:rabbit@192.168.100.225:5672")
targets = [
    oslo_messaging.Target(topic='notifications'),
]
endpoints = [NotificationEndpoint()]
pool = "notispy"
server = oslo_messaging.get_notification_listener(
    transport,
    targets,
    endpoints,
    # executor='eventlet',
    # pool=pool,
)

server.start()
server.wait()
