#!/usr/bin/env bash
set -x
export RANDOM_STRING="tempest-$RANDOM"
export GNOCCHI_SERVICE_URL=https://gnocchi.it.just.works
export AODH_SERVICE_URL=https://aodh.it.just.works
export ADMIN_TOKEN=$(openstack --os-cloud mosk-dev-admin token issue -f value -c id)
GABBIT=${1:-${HOME}/src/openstack/telemetry-tempest-plugin/telemetry_tempest_plugin/scenario/telemetry_integration_gabbits/aodh-gnocchi-threshold-alarm.yaml}
gabbi-run -k -x -- $GABBIT
