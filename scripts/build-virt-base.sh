pip install --user diskimage-builder

tmpkey=/tmp/ssh_tmp_pub_key_file

wget https://github.com/"${USER}".keys -O $tmpkey

export DIB_DEV_USER_USERNAME="${USER}"
export DIB_DEV_USER_PWDLESS_SUDO=true
export DIB_DEV_USER_AUTHORIZED_KEYS=$tmpkey
export DIB_DEV_USER_SHELL='/bin/bash'
export DIB_RELEASE='xenial'

disk-image-create ubuntu vm growroot cloud-init-nocloud devuser -o "${USER}"-virt-base -a amd64 --image-size 50

rm $tmpkey
