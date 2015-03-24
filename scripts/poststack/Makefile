SHELL=bash

help:
	@echo 'Makefile for a fixing DevStack'
	@echo ''
	@echo 'Usage:'
	@echo '   make wan           Allow WAN access for VMs'
	@echo '   make keypair       Create passwordless ssh key to access VMs'
	@echo '   make addimages     Add images for default AWS LoadBalancer resoure and Heat functional tests'
	@echo '   make dns           Add a DNS server fo default Neutron subnet'
	@echo '   make secgroup      Allow ICMP and SSH in default Neutron security group'
	@echo '   make all           Apply all fixes'
	@echo ''


all: wan keypair addimages dns secgroup

wan:
	@$(SHELL) wan.sh
keypair:
	@$(SHELL) keypair.sh
addimages:
	@$(SHELL) addimages.sh
dns:
	@$(SHELL) dns.sh
secgroup:
	@$(SHELL) secgroup.sh

.PHONY: wan keypair addimages dns secgroup
