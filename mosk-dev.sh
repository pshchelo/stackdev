# Working with MOSK virtual dev clusters
#
wget "https://mos-ci.infra.mirantis.net/job/deploy-k8s-ucp/$1/artifact/kubeconfig-child-cluster.yml" -O kubeconfig.yaml
~/dotfiles/scripts/mosk/mosk-dev-config-rename-context.sh kubeconfig.yaml
~/dotfiles/scripts/mosk/mosk-dev-fetch-deployed-resources.sh
~/dotfiles/scripts/k8s/k8s-cleanup-pods.sh -A
~/dotfiles/scripts/mosk/mosk-dev-create-resources.sh
# in a separate window startmosk-dev-connect
# ~/dotfiles/script/mosk/mosk-dev-connect
