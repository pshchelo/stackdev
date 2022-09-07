#!/usr/bin/env bash

ingress_lb_ip=$(kubectl -n openstack get svc ingress -ojsonpath='{.status.loadBalancer.ingress[0].ip}' --ignore-not-found)
if [ -n ${ingress_lb_ip} ]; then
    for svc in $(kubectl -n openstack get ingress -ojsonpath='{.items[*].spec.rules[*].host}'); do
        echo "${ingress_lb_ip} ${svc}"
    done
fi

keycloak_ip=$(kubectl -n iam get svc openstack-iam-keyclo-http -ojsonpath='{.status.loadBalancer.ingress[0].ip}' --ignore-not-found)
if [ -n ${keycloak_ip} ]; then
    keycloak_domain_record=$(kubectl -n coredns get cm coredns-coredns -oyaml | grep keycloak | awk '{print $1}')
    # keycloak_domain_record has dot (.) in the end since it is a proper DNS record
    echo "${keycloak_ip} ${keycloak_domain_record%?}"
fi
