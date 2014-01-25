#!/usr/bin/env python
from xml.dom import minidom
from xml.dom.minidom import Document
import sys

# Read in first arguement
input_file = sys.argv[1]

# parse our XML file
xml = minidom.parse(input_file)

# Get the DomainName or the VM Name
domainName = xml.getElementsByTagName('name')
domain_name = domainName[0].childNodes[0].nodeValue

# Get the hypervisor Type
domainHType = xml.getElementsByTagName('type')
h_type = domainHType[0].childNodes[0].nodeValue

# Get the Arch and OS
domainOSInfo = xml.getElementsByTagName('type')
for i in domainOSInfo:
    domain_arch = i.getAttribute('arch')
    domain_os = i.getAttribute('machine')

# Get Boot Device Type
domainBootDevType = xml.getElementsByTagName('boot')
for i in domainBootDevType:
    boot_dev_type = i.getAttribute('dev')

# Get disk Device location
for node in xml.getElementsByTagName("disk"):
    if node.getAttribute("device") == "disk":
        source = node.getElementsByTagName('source')
        for s in source:
            disk_loc = s.getAttribute('file')

# Get Boot Device
mapping = {}
for node in xml.getElementsByTagName("disk"):
    dev = node.getAttribute("device")
    target = node.getElementsByTagName('target')
    for t in target:
        mapping[dev] = t.getAttribute('dev')

if boot_dev_type == 'hd':
    boot_dev = mapping['disk']
elif boot_dev_type == 'cdrom':
    boot_dev = mapping['cdrom']

# Get amount of CPUS
domainVCPUs = xml.getElementsByTagName('vcpu')
vcpu_count = domainVCPUs[0].childNodes[0].nodeValue

# Get amount of RAM
domainMemory = xml.getElementsByTagName('memory')
memory = domainMemory[0].childNodes[0].nodeValue

# Create an empty XML Document
doc = Document()

# Create the "image" element
image = doc.createElement("image")
doc.appendChild(image)

# Create the Name Element
name_element = doc.createElement("name")
image.appendChild(name_element)
name_text = doc.createTextNode(domain_name)
name_element.appendChild(name_text)

# Create the Label Element
label_element = doc.createElement("label")
image.appendChild(label_element)
label_text = doc.createTextNode(domain_name)
label_element.appendChild(label_text)

# Create the Description Element
desc_element = doc.createElement("description")
image.appendChild(desc_element)
desc_text = doc.createTextNode(domain_os)
desc_element.appendChild(desc_text)

# Create the Domain Element
domain_element = doc.createElement("domain")
image.appendChild(domain_element)

# Create boot element
boot_element = doc.createElement("boot")
boot_element.setAttribute("type", h_type)
domain_element.appendChild(boot_element)

# Create guest Element
guest_element = doc.createElement("guest")
boot_element.appendChild(guest_element)

# Create the arch attribute
arch_element = doc.createElement("arch")
guest_element.appendChild(arch_element)
arch_text = doc.createTextNode(domain_arch)
arch_element.appendChild(arch_text)

# Create OS Element
os_element = doc.createElement("os")
boot_element.appendChild(os_element)

# Create the loader element and set the dev attribute
loader_element = doc.createElement("loader")
loader_element.setAttribute("dev", boot_dev_type)
os_element.appendChild(loader_element)

# Create drive element and set it's attributes
drive_element = doc.createElement("drive")
drive_element.setAttribute("disk", disk_loc)
drive_element.setAttribute("target", boot_dev)
boot_element.appendChild(drive_element)

# Create device Element
devices_element = doc.createElement("devices")
domain_element.appendChild(devices_element)

# Create VCPU text
vcpu_element = doc.createElement("vcpu")
devices_element.appendChild(vcpu_element)
vcpu_text = doc.createTextNode(vcpu_count)
vcpu_element.appendChild(vcpu_text)

# Create Memory text
memory_element = doc.createElement("memory")
devices_element.appendChild(memory_element)
memory_text = doc.createTextNode(memory)
memory_element.appendChild(memory_text)

# Create interface element
interface_element = doc.createElement("interface")
devices_element.appendChild(interface_element)

# Create graphics element
graphics_element = doc.createElement("graphics")
devices_element.appendChild(graphics_element)

# Create storage element
storage_element = doc.createElement("storage")
image.appendChild(storage_element)

# create disk element and set it's attributes
disk_element = doc.createElement("disk")
disk_element.setAttribute("file", disk_loc)
disk_element.setAttribute("format", "vmdk")
disk_element.setAttribute("use", "system")
storage_element.appendChild(disk_element)

f = open(input_file + '_converted', 'w')
f.write(doc.toprettyxml(indent=" ", encoding="utf-8"))
f.close()
