# after ghist charlesflynn/5576114
ip addr flush br-ex
sysctl -w net.ipv4.ip_forward=1
ip addr add 172.24.4.225/28 dev br-ex
ip link set br-ex up
route add -net 10.0.0.0/24 gw 172.24.4.226
