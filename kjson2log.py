#!/usr/bin/env python3
import json
import sys

with open(sys.argv[1]) as f:
    kibana = json.load(f)["hits"]["hits"]

log = []
for item in kibana:
    try:
        ts = item["fields"]["@timestamp"][0]
        s = item["_source"]
        pod = s["kubernetes"]["pod_name"]
        message = s.get("message", "UNPARSED_MESSAGE")
        host = s.get("hostname", "UNPARSED_HOST")
        module = s.get("module", "UNPARSED_MODULE")
        level = s.get("severity_label", "UNPARSED_LEVEL")
        logger = s.get("logger", "UNPARSED_LOGGER")
    except KeyError:
        raise Exception(item)
    log.append(f'{ts} - {host} - {pod} - {logger} - {level} - {module} - {message}')

for line in sorted(log):
    print(line)
