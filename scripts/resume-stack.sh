# enable ip forwarding (looks like devstack is already doing it itself)
#sudo sysctl -w net.ipv4.ip_forward=1
# reset bridges
# VALUES ARE FOR DEFAULT DEVSTACK FLOATING IP RANGE!
sudo ip addr flush br-ex
sudo ip addr add 172.24.4.1/24 dev br-ex
sudo ip link set br-ex up
# Not really needed for Neutron (may be Nova-network?)
#sudo route add -net 10.0.0.0/24 gw 172.24.4.1
# set iptables NAT so that VMs in principle can have internet access
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# attach stack-volumes
sudo losetup /dev/loop0 /opt/stack/data/stack-volumes-lvmdriver-1-backing-file
# run DevStack services
$HOME/devstack/rejoin-stack.sh
