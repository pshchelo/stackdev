# My default local.conf already loads Cirros qcow2 image instead of UEC ones,
# and Heat loads Fedora20 image, but Heat's AWS load balancer expects different name,
# so I like them images all renamed.

. /opt/stack/devstack/accrc/admin/admin
# Get and rename the Cirros qcow2 image
testvm=$(glance image-list --disk-format qcow2 | awk 'NR>2 {print $4}'| grep cirros)
if [ -n "$testvm" ]; then
    glance image-update $testvm --name TestVM --property description=$testvm
fi

# Get and rename Fedora20 image
fedora20=$(glance image-list --disk-format qcow2 | awk 'NR>2 {print $4}' | grep Fedora.*20)
if [ -n "$fedora20" ]; then
    glance image-update $fedora20 --name F20-x86_64-cfntools --property description=$fedora20
fi

# Create passwordless ssh key to access VMs
. /opt/stack/devstack/accrc/demo/demo
nova keypair-add demo > $HOME/demo.pem
chmod 600 $HOME/demo.pem

glance image-list
nova keypair-list
