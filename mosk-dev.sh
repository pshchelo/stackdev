# Working with MOSK virtual dev clusters
if [ -z "$1" ]; then
    echo "need deploy-openstack-k8s-env job number"
    exit 1
fi
wget "https://mos-ci.infra.mirantis.net/job/deploy-openstack-k8s-env/$1/artifact/kubeconfig-child-cluster.yml" -O kubeconfig.yaml
~/dotfiles/scripts/mosk/mosk-dev-config-rename-context.sh kubeconfig.yaml
~/dotfiles/scripts/mosk/mosk-dev-fetch-deployed-resources.sh
~/dotfiles/scripts/k8s/k8s-cleanup-pods.sh -A
# the next command needs mosk-dev-connect running,
# but it will pause if that is not running yet
~/dotfiles/scripts/mosk/mosk-dev-create-resources.sh
