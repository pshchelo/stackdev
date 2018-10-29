#!/usr/bin/env python

import argparse
import sys
import xml.etree.ElementTree as ET

import libvirt

KERNEL_OPTS = ' '.join(['ipa-standalone=1',
                        'nofb nomodeset',
                        'vga=normal',
                        'console=ttyS0',
                        'systemd.journald.forward_to_console=yes'])


def restart_to_kernel(conn, domain, kernel, initrd):
    xml = ET.fromstring(domain.XMLDesc())
    os_elem = xml.find('os')
    kernel_el = ET.SubElement(os_elem, 'kernel')
    kernel_el.text = kernel
    initrd_el = ET.SubElement(os_elem, 'initrd')
    initrd_el.text = initrd
    cmdline_el = ET.SubElement(os_elem, 'cmdline')
    cmdline_el.text = KERNEL_OPTS
    conn.createXML(ET.tostring(xml))


def restart_to_hdd(conn, domain):
    xml = ET.fromstring(domain.XMLDesc())
    os_elem = xml.find('os')
    for el_name in ('kernel', 'initrd', 'cmdline'):
        el = ET.SubElement(os_elem, el_name)
        os_elem.remove(el)
    kernel_el = ET.SubElement(os_elem, 'kernel')
    os_elem.remove(kernel_el)
    initrd_el = ET.SubElement(os_elem, 'initrd')
    os_elem.remove(initrd_el)
    cmdline_el = ET.SubElement(os_elem, 'cmdline')
    os_elem.remove(cmdline_el)
    conn.createXML(ET.tostring(xml))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('domain', type=str, help="Name of the VM to manage")
    parser.add_argument('target', type=str, choices=['direct', 'hdd'],
                        help='Set boot mode and (re)start.'),
    parser.add_argument('--libvirt', type=str, default=None,
                        help='Libvirt URI to connect to'),
    parser.add_argument('--kernel', type=str, default=None,
                        help="Kernel to boot with, "
                        "required when booting as 'direct'")
    parser.add_argument('--initrd', type=str, default=None,
                        help="Initrd to boot with, "
                        "required when booting as 'direct'")
    parsed = parser.parse_args()
    if parsed.target == 'direct' and not (parsed.kernel and parsed.initrd):
        print("Supply kernel and initrd path when booting as 'direct'")
        sys.exit(1)
    return parsed


def main():
    args = parse_args()
    if not args.libvirt:
        conn = libvirt.open()
    else:
        conn = libvirt.open(args.libvirt)
    domain = conn.lookupByName(args.domain)
    if domain.info()[0] == libvirt.VIR_DOMAIN_RUNNING:
        domain.destroy()
    if args.target == 'direct':
        restart_to_kernel(conn, domain, args.kernel, args.initrd)
    elif args.target == 'hdd':
        restart_to_hdd(conn, domain)
    conn.close()


if __name__ == '__main__':
    main()
