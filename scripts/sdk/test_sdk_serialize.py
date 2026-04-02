import json
import unittest

import openstack

PORT_NAME = "demotest"

class SdkMarshallTest(unittest.TestCase):
    maxDiff = None
    def setUp(self):
        cloud = openstack.connect()
        self.port = cloud.get_port(PORT_NAME)
        self.port["admin_state"] = "UP"
    def test_in(self):
        self.assertEqual("UP", self.port["admin_state"])
        self.assertEqual("UP", self.port.admin_state)
        self.assertIn("admin_state", self.port)
    def test_marshall(self):
        self.assertEqual("UP", self.port["admin_state"])
        self.assertEqual("UP", self.port.admin_state)
        marshalled_port = json.loads(json.dumps(self.port))
        self.assertIn("admin_state", marshalled_port)
