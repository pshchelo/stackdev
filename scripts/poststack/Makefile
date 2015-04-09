SHELL=bash

help:
	@echo 'Makefile for a fixing DevStack'
	@echo ''
	@echo 'Usage:'
	@echo '   make wan           Allow WAN access for VMs'
	@echo '   make keypair       Add ssh key to Nova'
	@echo '   make heatimage     Add image for Heat functional tests'
	@echo '   make awslbimage    Add images for default AWS LoadBalancer resoure'
	@echo '   make addimages     Add images for default AWS LoadBalancer resoure and Heat functional tests'
	@echo '   make rncirros      Rename available cirros qcow image as "cirros"'
	@echo '   make dns           Add a DNS server fo default Neutron subnet'
	@echo '   make secgroup      Allow ICMP and SSH in default Neutron security group'
	@echo '   make all           Apply all fixes except loading new images'
	@echo ''


all: wan keypair dns secgroup rncirros

wan:
	@$(SHELL) wan.sh
keypair:
	@$(SHELL) keypair.sh
heatimage:
	@$(SHELL) heatimage.sh
awslbimage:
	@$(SHELL) awslbimage.sh
addimages: heatimage awslbimage
rncirros:
	@$(SHELL) rncirros.sh
dns:
	@$(SHELL) dns.sh
secgroup:
	@$(SHELL) secgroup.sh

.PHONY: wan keypair addimages dns secgroup heatimage awslbimage rncirros
