# Exactly following a tutorial/task OSST-164

# create bridge
brctl addbr vbridge10

# the next two commands are while we are building very simple network,
# so the network discovery is not needed

# turn STP on the bridge off
brctl stp vbridge10 off
# set forwarding delay on the bridge to 0 seconds
brctl setfd vbridge10 0

# set naming scheme for VLANs
vconfig set_name_type DEV_PLUS_VID_NO_PAD
# create VLAN and assign it number 10
vconfig add eth0 10

# set MAC address of the VLAN adapter (why?..)
ip link set eth0.10 address fe:ff:ff:ff:ff:ff

# bring up the VLAN adapter
ip link set eth0.10 up
#bring up the bridge
ip link set vbridge10 up
# assign VLAN adapter to bridge
brctl addif vbridge10 eth0.10
