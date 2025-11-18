#!/usr/bin/env bash
namespace=$1
if [[ -n $namespace ]]; then
    apiresources=$(kubectl api-resources --verbs=list --namespaced -o name)
    for res in ${apiresources}; do
        if [[ ! ${res} =~ "events" ]]; then
            kubectl get --show-kind --ignore-not-found -n ${namespace} ${res} -o name
        fi
    done
else
    kubectl api-resources --verbs=list --namespaced=false -o name | 
        xargs -n 1 kubectl get --show-kind --ignore-not-found -o name
fi
