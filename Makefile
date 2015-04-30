# Fixes to apply after DevStack's stack.sh run

DEMO_CREDS=. /opt/stack/devstack/accrc/demo/demo
ADMIN_CREDS=. /opt/stack/devstack/accrc/admin/admin
IS_NEUTRON=`keystone catalog | grep "Service: network"`

DISKFMT=qcow2
ADD_IMAGE=glance image-create --is-public True --disk-format $(DISKFMT) --container-format bare --copy-from

CIRROS_VERSION=0.3.3
CIRROS_IMAGE_NAME=cirros-$(CIRROS_VERSION)-x86_64-disk
CIRROS_IMAGE_URL="http://download.cirros-cloud.net/$(CIRROS_VERSION)/$(CIRROS_IMAGE_NAME).img"

HEAT_FUNC_IMAGE_NAME=fedora-heat-test-image
HEAT_FUNC_IMAGE_URL="http://tarballs.openstack.org/heat-test-image/$(HEAT_FUNC_IMAGE_NAME).$(DISKFMT)"

AWS_LB_IMAGE_NAME=Fedora-Cloud-Base-20141203-21.x86_64
AWS_LB_IMAGE_URL="http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/$(AWS_LB_IMAGE_NAME).$(DISKFMT)"

help:
	@echo 'Customize deployed DevStack '
	@echo ''
	@echo 'Usage:'
	@echo '   make wan           Allow WAN access for VMs'
	@echo '   make keypair       Add my ssh key to Nova'
	@echo '   make addcirros     Add latest cirros qcow image'
	@echo '   make heatimage     Add image for Heat functional tests'
	@echo '   make awslbimage    Add images for default AWS LoadBalancer resoure'
	@echo '   make cirros        Rename available cirros qcow image to "cirros"'
	@echo '   make dns           Add a DNS server fo default Neutron subnet'
	@echo '   make secgroup      Allow ICMP and SSH in default Neutron security group'
	@echo '   make stack         Apply all fixes except loading new images'
	@echo ''


stack: wan keypair dns secgroup cirros

wan:
	@WAN_SET=$$(sudo iptables -t nat -L | grep 'MASQUERADE.*all.*anywhere.*anywhere');\
	if [ -z "$$WAN_SET" ]; then \
	    echo "Allowing WAN access for VMs";\
	    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; \
	fi
	
keypair:
	@echo "Adding demo keypair..."; \
$(DEMO_CREDS); \
nova keypair-add demo --pub_key $$HOME/.ssh/git_rsa.pub; \
nova keypair-list

# space in grep is important, now there are two subnets, ipv4 and ipv6
dns:
	@echo "Adding Google DNS to demo tenant private subnets..."; \
$(DEMO_CREDS); \
if [ "$(IS_NEUTRON)" ]; then \
    dnsserver4=8.8.8.8; \
    dnsserver6="2001:4860:4860::8888"; \
    subnet4=$$(neutron subnet-list | grep " private-subnet" | awk '{print $$2}'); \
    neutron subnet-update $$subnet4 --dns-nameserver $$dnsserver4; \
    neutron subnet-show $$subnet4; \
    subnet6=$$(neutron subnet-list | grep "ipv6-private-subnet" | awk '{print $$2}'); \
    neutron subnet-update $$subnet6 --dns-nameserver $$dnsserver6; \
    neutron subnet-show $$subnet6; \
fi

secgroup:
	@echo "Adding ingress ICMP and SSH to default security group..."; \
$(DEMO_CREDS); \
if [ "$(IS_NEUTRON)" ]; then \
    neutron security-group-rule-list -f csv -c id -c security_group -c direction | grep 'default.*ingress' | awk -F "," '{print $$1}' | xargs -L1 neutron security-group-rule-delete; \
    neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol ICMP; \
    neutron security-group-rule-create default --direction ingress --remote-ip-prefix "0.0.0.0/0" --ethertype IPv4 --protocol TCP --port-range-min 22 --port-range-max 22; \
fi

cirros:
	@echo "Renaming cirros image..."; \
$(ADMIN_CREDS); \
name=$$(glance image-list | grep -o "cirros-.*-disk"); \
glance image-update $$name --name cirros --property description=$$name

addcirros:
	@echo "Uploading latest Cirros qcow image..."; \
$(ADMIN_CREDS); \
$(ADD_IMAGE) $(CIRROS_IMAGE_URL) --name cirros --property description="$(CIRROS_IMAGE_NAME)"

heatimage:
	@echo "Uploading Heat test image to glance";\
$(ADMIN_CREDS);\
$(ADD_IMAGE) $(HEAT_FUNC_IMAGE_URL) --name $(HEAT_FUNC_IMAGE_NAME)

awslbimage:
	@echo "Uploading Fedora 21 cloud image to glance";\
$(ADMIN_CREDS);\
$(ADD_IMAGE) $(AWS_LB_IMAGE_URL) --name $(AWS_LB_IMAGE_NAME)

.PHONY: wan keypair dns secgroup cirros addcirros heatimage awslbimage 
