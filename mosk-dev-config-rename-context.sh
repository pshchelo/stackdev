in_file=$1
if [ -z $in_file ]; then
    echo need file to act on
    exit 1
fi
new_name=${2:-$(basename $PWD)}
old_name=$(kubectl --kubeconfig $in_file config get-contexts -oname)
sed -i "s/: $old_name/: $new_name/" $in_file
kubectl --kubeconfig $in_file config set-context $new_name --namespace openstack
kubectl --kubeconfig $in_file config use-context $new_name
chmod 600 $in_file
