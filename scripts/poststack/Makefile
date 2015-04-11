SHELL=bash

WAN_SET=$(sudo iptables -t nat -L | grep 'MASQUERADE.*all.*anywhere.*anywhere')
DEMO_CREDS=. /opt/stack/devstack/accrc/demo/demo
ADMIN_CREDS=. /opt/stack/devstack/accrc/admin/admin
IS_NEUTRON=`keystone catalog | grep "Service: network"`


help:
	@echo 'Makefile for a fixing DevStack'
	@echo ''
	@echo 'Usage:'
	@echo '   make wan           Allow WAN access for VMs'
	@echo '   make keypair       Add ssh key to Nova'
	@echo '   make heatimage     Add image for Heat functional tests'
	@echo '   make awslbimage    Add images for default AWS LoadBalancer resoure'
	@echo '   make cirros        Rename available cirros qcow image as "cirros"'
	@echo '   make dns           Add a DNS server fo default Neutron subnet'
	@echo '   make secgroup      Allow ICMP and SSH in default Neutron security group'
	@echo '   make all           Apply all fixes except loading new images'
	@echo ''


all: wan keypair dns secgroup cirros

wan:
	@if [ -z "$(WAN_SET)" ]; then \
	    echo "Allowing WAN access for VMs";\
	    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; \
	fi
	
keypair:
	@echo "Adding demo keypair..."; \
$(DEMO_CREDS); \
nova keypair-add demo --pub_key $$HOME/.ssh/git_rsa.pub; \
nova keypair-list

cirros:
	@echo "Renaming cirros image..."; \
$(ADMIN_CREDS); \
name=$$(glance image-list | grep -o "cirros-.*-disk"); \
glance image-update $$name --name cirros --property description=$$name

dns:
	@echo "Adding Google DNS to demo tenant subnet..."; \
$(DEMO_CREDS); \
if [ "$(IS_NEUTRON)" ]; then \
    dnsserver=8.8.8.8; \
    subnet=$$(neutron subnet-list | grep private-subnet | awk '{print $$2}'); \
    neutron subnet-update $$subnet --dns-nameserver $$dnsserver; \
    neutron subnet-show $$subnet; \
fi

secgroup:
	@echo "Adding ingress ICMP and SSH to default security group..."; \
$(DEMO_CREDS); \
if [ "$(IS_NEUTRON)" ]; then \
    neutron security-group-rule-list -f csv -c id -c security_group -c direction | grep 'default.*ingress' | awk -F "," '{print $$1}' | xargs -L1 neutron security-group-rule-delete; \
    neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol ICMP; \
    neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol TCP --port-range-min 22 --port-range-max 22; \
fi

heatimage:
	@$(SHELL) heatimage.sh
awslbimage:
	@$(SHELL) awslbimage.sh

.PHONY: wan keypair dns secgroup heatimage awslbimage cirros
