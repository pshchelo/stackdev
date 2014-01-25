# first edit /etc/fuse.conf
# sudo sed 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
sshfs -o allow_other -o reconnect 172.18.194.60:/home/pshchelokovskyy/devel ~/devel
