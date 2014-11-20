#! /usr/bin/env python

import os
from keystoneclient.v3 import client

USERNAME=os.environ.get('OS_USERNAME', None)
PASSWORD = os.environ.get('OS_PASSWORD', None)
AUTH_URL = os.environ.get('OS_AUTH_URL', '').replace('v2.0', 'v3')

kc = client.Client(username=USERNAME, password=PASSWORD,
                  auth_url=AUTH_URL, endpoint=AUTH_URL,
                  verify=False)
kc.authenticate()
