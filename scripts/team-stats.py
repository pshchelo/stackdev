#!/usr/bin/env python3

import calendar
import datetime
import time

import requests
from urllib import parse as urlparse

TEAM = [
    'pshchelo',
    'vmarkov',
    'aarefiev',
]

START = datetime.datetime(2021, 1, 1).utctimetuple()
END = datetime.datetime(2021, 12, 31).utctimetuple()

stackalytics = "https://www.stackalytics.io/api/1.0/"

adapter = requests.adapters.HTTPAdapter()

session = requests.Session()

session.mount(stackalytics, adapter)
session.verify = False

stats = []

for name in TEAM:
    params = {
        'release': 'all',
        'user_id': name,
        'start_date': calendar.timegm(START),
        'end_date': calendar.timegm(END),
    }

    url = urlparse.urljoin(stackalytics, 'contribution')
    resp = session.get(url, params=params)
    if resp.status_code != requests.codes.OK:
        print("Failed to fetch stats for user {}".format(name))
        continue
    data = resp.json()['contribution']
    data['user_id'] = name
    data['reviews'] = sum(data['marks'][mark]
                          for mark in map(str, range(-2, 3)))
    stats.append(data)

totals = {}

for field, value in stats[0].items():
    if isinstance(value, int):
        totals[field] = sum(item[field] for item in stats)

print("start: {}".format(time.strftime("%x", START)))
print("end: {}".format(time.strftime("%x", END)))

for key, val in totals.items():
    print("{field} = {total}".format(field=key, total=val))
