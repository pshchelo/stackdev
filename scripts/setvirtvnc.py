#!/usr/bin/env python

"""Replace VNC connection settings in VMs."""

import xml.etree.ElementTree as ET

import libvirt

conn = libvirt.open()

domains = conn.listAllDomains()

for domain in domains:
    doc = ET.fromstring(domain.XMLDesc())
    for graphics in doc.iter('graphics'):
        if graphics.attrib['type'] == 'vnc':
            text = graphics.text
            graphics.clear()
            graphics.text = text
            graphics.attrib['type'] = 'vnc'
            graphics.attrib['port'] = '-1'
            graphics.attrib['autoport'] = 'yes'
    conn.defineXML(ET.tostring(doc))
