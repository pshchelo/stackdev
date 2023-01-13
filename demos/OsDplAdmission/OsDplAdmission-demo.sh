#!/usr/bin/env bash
clear
SELF_PATH=$(dirname "$(realpath -s "$0")")
source ${SELF_PATH}/../demottype # exports teletype and telerun functions
cat ${SELF_PATH}/../mirantis-logo.txt

teletype "AdmissionController for OpenStackDeployment custom resource"
sleep 3
clear

teletype "OpenStack is a complex collection of components and (micro)services."
echo
teletype "The community tests and supports only N -> N+1 upgrade between releases,"
teletype "with no support for downgrades or skip-level upgrades."
teletype "Such logic is impossible to express via OpenAPIv3 schema "
teletype "used in CustomResourceDefinition resources."
echo
teletype "Kubernetes Admission Controllers to the rescue!"
teletype "These allow to extend Kubernetes API logic for validating resources,"
teletype "immediately disallowing creation or update of a resource to the API user."
sleep 2
echo
teletype "We have implemented an admission controller that enforces, among others,"
teletype "the order in which OpenStack can be upgraded."
teletype "It is deployed and registered together with our controller"
teletype "for the custom OpenStackDeployment resource:"
telerun kubectl -n osh-system get deploy
telerun kubectl -n osh-system get pod
sleep 2
teletype "Here is a minimal OpenStackDeployment resource that passes current OpenAPIv3 schema definition"
telerun cat minimalOsDpl.yaml
sleep 3
echo
teletype "I am using draft=true, so that no actual resources will be created,"
teletype "and we do not have to wait 40+ minutes on each upgrade."
echo
teletype "Currently the OpenStack version is set to the lowest one we support - Queens"
teletype "Let's create this resource"
telerun kubectl apply -f minimalOsDpl.yaml
sleep 2
teletype "Now let's upgrade it to the next release (Rocky)"
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"rocky"}}'
teletype "Success"
sleep 2
echo
teletype "Now let's try downgrade back"
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"queens"}}'
teletype "Admission controller does not allow it"
sleep 2
echo
teletype "Now let's try skip-level upgrade skipping next version (Stein) straight to Train"
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"train"}}'
teletype "Not allowed as well, with appropriate message too."
sleep 2
echo
teletype "Now let's upgrade properly, step-by-step, to the latest supported version"
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"stein"}}'
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"train"}}'
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"ussuri"}}'
teletype "Success!"
sleep 2
echo
teletype "Additionally we also can deploy master version of OpenStack."
teletype "It is used internally to be prepared to what comes in the next release."
teletype "However it is obviously not stable enough for production, and it lacks our downstream hardening,"
teletype "so using the admission controller we also deny attempts to upgrade to (or install) master version."
echo
teletype "Let's try upgrade:"
telerun kubectl -n openstack patch osdpl minimal-demo --type=merge --patch '{"spec":{"openstack_version":"master"}}'
teletype "Not allowed, and tells what to do if you really need it."
sleep 2
teletype "That's all for today, thank you for your attention."
telerun kubectl -n openstack delete osdpl minimal-demo
