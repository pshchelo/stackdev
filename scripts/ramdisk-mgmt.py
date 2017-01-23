#!/usr/bin/env python

import argparse
import xml.etree.ElementTree as ET

import libvirt

DOMAIN = 'ramdisk'

KERNEL = '/home/pshchelo/images/tinyipa/latest/tinyipa-master.vmlinuz'
INITRAMFS = '/home/pshchelo/images/tinyipa/latest/ansible-tinyipa-master.gz'
KERNEL_OPTS = ' '.join(['ipa-standalone=1',
                        'nofb nomodeset',
                        'vga=normal',
                        'console=ttyS0',
                        'systemd.journald.forward_to_console=yes'])


def restart_to_kernel(domain, kernel, initrd):
    domain.destroy()
    xml = ET.fromstring(domain.XMLDesc())
    os = xml.find('os')
    kernel_el = ET.SubElement(os, 'kernel')
    kernel_el.text = kernel
    initrd_el = ET.SubElement(os, 'initrd')
    initrd_el.text = initrd
    cmdline_el = ET.SubElement(os, 'cmdline')
    cmdline_el.text = KERNEL_OPTS
    conn.createXML(ET.tostring(xml))


def restart_to_hdd(domain):
    domain.destroy()
    xml = ET.fromstring(domain.XMLDesc())
    os = xml.find('os')
    for el_name in ('kernel', 'initrd', 'cmdline'):
        el = ET.SubElement(os, el_name)
        os.remove(el)
    kernel_el = ET.SubElement(os, 'kernel')
    os.remove(kernel_el)
    initrd_el = ET.SubElement(os, 'initrd')
    os.remove(initrd_el)
    cmdline_el = ET.SubElement(os, 'cmdline')
    os.remove(cmdline_el)
    conn.createXML(ET.tostring(xml))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('target', type=str, choices=['direct', 'hdd'],
                        help='Set boot mode and restart.')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    conn = libvirt.open()
    domain = conn.lookupByName(DOMAIN)
    if args.target == 'direct':
        restart_to_kernel(domain, KERNEL, INITRAMFS)
    elif args.target == 'hdd':
        restart_to_hdd(domain)
    conn.close()
