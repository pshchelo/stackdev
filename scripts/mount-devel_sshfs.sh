# first edit /etc/fuse.conf
# sudo sed 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
sshfs -o allow_other -o reconnect 172.18.196.53:/home/pshchelo/devel ~/devel
