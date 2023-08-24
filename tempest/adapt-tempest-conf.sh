#!/usr/bin/env bash
tempest_conf=${1:-tempest.conf}
crudini --del $tempest_conf identity ca_certificates_file
crudini --set $tempest_conf identity disable_ssl_certificate_validation True
crudini --set $tempest_conf identity v3_endpoint_type public
crudini --set $tempest_conf identity uri_v3 https://keystone.it.just.works/v3
#crudini --set $tempest_conf DEFAULT state_path FIXME
#crudini --set $tempest_conf load_balancer test_server_path FIXME
#crudini --set $tempest_conf scenario img_file FIXME
