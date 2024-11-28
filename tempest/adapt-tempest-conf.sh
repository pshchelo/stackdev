#!/usr/bin/env bash
tempest_pod=$(kubectl -n openstack get pod -l application=tempest,component=run-tests -o jsonpath='{.items[*].metadata.name}')

kubectl -n openstack cp -c tempest-run-tests "$tempest_pod:/etc/tempest/test-blacklist" ./test-blacklist

tempest_conf=${PWD}/tempest.conf
kubectl -n openstack cp -c tempest-run-tests "$tempest_pod:/etc/tempest/tempest.conf" "$tempest_conf"

crudini --del "$tempest_conf" identity ca_certificates_file
crudini --set "$tempest_conf" identity disable_ssl_certificate_validation True
crudini --set "$tempest_conf" identity v3_endpoint_type public
crudini --set "$tempest_conf" identity uri_v3 https://keystone.it.just.works/v3

resources_dir=${PWD}/resources
mkdir -p "$resources_dir"
crudini --set "$tempest_conf" DEFAULT state_path "$resources_dir"

remote_img_file_path=$(crudini --get "$tempest_conf" scenario img_file)
kubectl -n openstack cp -c tempest-run-tests "$tempest_pod:$remote_img_file_path" "$resources_dir/test.img"
crudini --set "$tempest_conf" scenario img_file "$resources_dir/test.img"

remote_test_server_path=$(crudini --get "$tempest_conf" load_balancer test_server_path)
kubectl -n openstack cp -c tempest-run-tests "$tempest_pod:$remote_test_server_path" "$resources_dir/test_server.bin"
crudini --set "$tempest_conf" load_balancer test_server_path "$resources_dir/test_server.bin"

remote_test_accounts_file=$(crudini --get "$tempest_conf" auth test_accounts_file)
if [ -n "$remote_test_accounts_file" ]; then
    kubectl -n openstack cp -c tempest-run-tests "$tempest_pod:$remote_test_accounts_file" "$resources_dir/static_accounts.yaml"
    crudini --set "$tempest_conf" auth test_accounts_file "$resources_dir/static_accounts.yaml"
    mkdir -p "$resources_dir/locks"
    crudini --set "$tempest_conf" oslo_concurrency lock_path "$resources_dir/locks"
fi

cat > run-tempest.sh << EOF
#!/usr/bin/env bash
tempest run --config-file ./tempest.conf --blacklist-file ./test-blacklist \$@
EOF
chmod +x run-tempest.sh
