#!/usr/bin/env bash
# Run Python unit tests in container, almost the same as MCP/MOSK CI does
image_repo="docker-dev-virtual.docker.mirantis.net"
image_path="mirantis/openstack-ci/openstack-ci-python3-test"
image_tag="noble"
UPPER_CONSTRAINTS_FILE=${UPPER_CONSTRAINTS_FILE:-"$HOME/src/openstack/requirements/upper-constraints.txt"}
DEBUG=0
VERBOSE=0
TOX_VER=""
VENV_VER=""

function get_help {
    local script_name
    script_name=$(basename "$0")
    echo "Usage: $script_name TOX_ENV [-r <docker repo url>] [-i <docker image path>] [-t <docker image tag>] [-x <tox version specifier>] [-e <virtualenv version specifier>] [-h] [-v] [-d]"
    echo "defaults are:"
    echo "<docker repo url> $image_repo"
    echo "<docker image path> $image_path"
    echo "<docker image tag> $image_tag"
}

positional_args=()
while [ $OPTIND -le "$#" ]; do
    if getopts ':r:i:t:x:e:hvd' arg; then
        case "${arg}" in
            r) image_repo="${OPTARG}" ;;
            i) image_path="${OPTARG}" ;;
            t) image_tag="${OPTARG}" ;;
            v) VERBOSE=1; set -x ;;
            x) TOX_VER="${OPTARG}" ;;
            e) VENV_VER="${OPTARG}" ;;
            d) DEBUG=1 ;;
            h) get_help; exit 0 ;;
            ?) get_help; exit 1 ;;
        esac
    else
        positional_args+=("${!OPTIND}")
        ((OPTIND+=1))
    fi
done

tox_env=${positional_args[0]}
if [ -z "$tox_env" ]; then
    get_help
    exit 1
fi

name="mcp-ci-$tox_env"
image="$image_repo/$image_path:$image_tag"
# This is how it is started on CI, in this example for python-openstackclient
# workspace dir has both 'python-openstackclient' and 'requirements' dirs
#docker run -d -t \
#    --group-add jenkins \
#    --group-add 1001 \
#    -e LC_ALL=en_US.UTF-8 \
#    -e TOX_ENV=py38 \
#    -e VIRTUALENV_VER= \
#    -e TOX_VER=<4.0.0
#    -e UPPER_CONSTRAINTS_FILE=/var/lib/jenkins/workspace/yoga-openstack-test-py38-focal/requirements/upper-constraints.txt \
#    -e TOX_CONSTRAINTS_FILE=/var/lib/jenkins/workspace/yoga-openstack-test-py38-focal/requirements/upper-constraints.txt \
#    -e WORKSPACE=/var/lib/jenkins/workspace/yoga-openstack-test-py38-focal \
#    -w /var/lib/jenkins/workspace/yoga-openstack-test-py38-focal/python-openstackclient \
#    -v /var/run/docker.sock:/var/run/docker.sock \
#    -v /var/lib/jenkins/workspace/yoga-openstack-test-py38-focal:/var/lib/jenkins/workspace/yoga-openstack-test-py38-focal \
#    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
#    --name jenkins-yoga-openstack-test-py38-focal-592 \
#    docker-dev-virtual.docker.mirantis.net/mirantis/openstack-ci/openstack-ci-python3-test:focal \
#    /bin/cat

docker_args="-d -t"
docker_args+=" --name $name"
docker_args+=" --group-add jenkins"
docker_args+=" --group-add 1000"
docker_args+=" -e LC_ALL=en_US.UTF-8"
docker_args+=" -e TOX_ENV=$tox_env"
docker_args+=" -e TOX_VER=$TOX_VER"
docker_args+=" -e VIRTUALENV_VER=$VENV_VER"
docker_args+=" -e UPPER_CONSTRAINTS_FILE=/opt/upper-constraints.txt"
docker_args+=" -e TOX_CONSTRAINTS_FILE=/opt/upper-constraints.txt"
docker_args+=" -e WORKSPACE=/opt/project"
docker_args+=" -w /opt/project"
docker_args+=" -v $PWD:/opt/project"
docker_args+=" -v $UPPER_CONSTRAINTS_FILE:/opt/upper-constraints.txt"
docker_args+=" -v /var/run/docker.sock:/var/run/docker.sock"
dns_ip=$(resolvectl status tun0 | grep "^Current" | awk -F ': ' '{print $2}')
if [ -n "$dns_ip" ]; then
    docker_args+=" --dns $dns_ip"
fi

if [ -d "$PWD/.tox" ]; then
    rm -rf "$PWD/.tox/" || sudo rm -rf "$PWD/.tox/"
fi
set -x
# shellcheck disable=SC2086 # docker_args is meant to be word-split
docker run $docker_args "$image" /bin/cat
set +x
if [ $VERBOSE = 1 ]; then
    set -x
fi

venv="virtualenv"
if [ -n "$VIRTUALENV_VER" ]; then
    venv="$venv==$VIRTUALENV_VER"
fi

docker exec -t -u root:root "$name" groupmod -g "${UID}" jenkins
docker exec -t -u root:root "$name" usermod -u "${UID}" jenkins
docker exec -t -u root:root "$name" bash -c 'echo -e "break-system-packages=true" >> /etc/pip.conf'
docker exec -t -u root:root "$name" pip uninstall virtualenv --yes
docker exec -t -u root:root "$name" pip install -c /opt/upper-constraints.txt "$venv"

docker exec -t -u jenkins:jenkins "$name" /usr/local/bin/run_dockerized_tox.sh

if [[ $DEBUG -eq 0 ]]; then
    docker stop "$name"
    docker rm "$name"
fi
