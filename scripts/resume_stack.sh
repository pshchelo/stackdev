# enable ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1
# reset bridges
sudo ip addr flush br-ex
sudo ip addr add 172.24.4.1/24 dev br-ex
sudo ip link set br-ex up
sudo route add -net 10.0.0.0/24 gw 172.24.4.1
# set iptables NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# attach stack-volumes
sudo losetup /dev/loop0 /opt/stack/data/stack-volumes-backing-file
# run DevStack services
. ~/devstack/rejoin_stack.sh
