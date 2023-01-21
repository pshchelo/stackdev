#!/usr/bin/env bash
clear
SELF_PATH=$(dirname "$(realpath -s "$0")")
source ${SELF_PATH}/../demottype # exports teletype and telerun functions
cat ${SELF_PATH}/../mirantis-logo.txt

# for preparation steps, see $SELF_PATH/prepare-demo.sh

teletype "Dynamic control of OpenStack compute resource oversubscription"
sleep 3
clear
echo
teletype "A standard way to control oversubscription in OpenStack compute"
teletype "service was for a long time to change '{cpu,disk,ram}_allocation_ratio'"
teletype "options for every nova-compute service in question."
sleep 3
echo
teletype "Such change however requires compute service restarts to take an effect,"
teletype "and thus may lead to disruptions."
sleep 3
echo
teletype "However, since some releases already, OpenStack Compute can be configured"
teletype "in such a way that the oversubscription can be controlled dynamically,"
teletype "on demand, through the OpenStack Placement service API."
sleep 3
echo
teletype "And with 23.1, MOSK is now configured in such a way by default."
teletype "Let's see that in action!"
sleep 3
clear

teletype "I have a toy developer environment, initially deployed with 2 compute nodes."
teletype "For a clearer showcase I have removed one of the compute nodes"
teletype "by both removing compute node labels and also manually deleting"
teletype "its compute service, which also deletes the corresponding "
teletype "resource provider in the Placement service."
teletype "I also configured the env with custom, lower than default,"
teletype "CPU allocation ratio."
teletype "Long story short, the current state is as follows:"
sleep 4
teletype "Relevant settings in OsDpl:"
telerun kubectl -n openstack get osdpl osh-dev -ojsonpath='{.spec.features.nova.allocation_ratios}'
sleep 2
echo
teletype "Current single compute node as Kubernetes node:"
telerun kubectl get nodes -l openstack-compute-node=enabled
sleep 2
teletype "The 'spare' node to be added later as a compute:"
telerun kubectl get nodes -l openstack-compute-node!=enabled,openstack-control-plane!=enabled,tempest!=enabled,node-role.kubernetes.io/master!=
spare_node=$(kubectl get nodes -l openstack-compute-node!=enabled,openstack-control-plane!=enabled,tempest!=enabled,node-role.kubernetes.io/master!= -o custom-columns=NAME:.metadata.name --no-headers)

teletype "Current resource providers in Placement service:"
telerun openstack resource provider list
teletype "A single provider for the single compute node."
first_resprov_id=$(openstack resource provider list -f value -c uuid)
echo
teletype "Current usage on that resource provider:"
telerun openstack resource provider usage show $first_resprov_id
teletype "It is empty, no instances, no resources consumed."
sleep 2
teletype "Current overcommit values on that resource provider:"
telerun openstack resource provider inventory list $first_resprov_id
teletype "Same custom small one as set in OsDpl."
sleep 2

teletype "I have a flavor that consumes as much CPU as possible"
teletype "(one can not create an instance with CPUs more than actual physical cores):"
telerun openstack flavor show maxCPU
teletype "Boot 2 instances with this flavor to saturate the compute node"
teletype "(not bothering with networking)..:"
telerun openstack --os-compute-api-version 2.37 server create it-fits --nic none --flavor maxCPU --image Cirros-6.0 --min 2 --max 2 --wait
teletype "Try to boot one more another instance:"
telerun openstack --os-compute-api-version 2.37 server create does-not-fit --nic none --flavor maxCPU --image Cirros-6.0 --wait
telerun openstack server show does-not-fit -f json -c fault
teletype "As expected, we eventually get NoValidHost error"
teletype "as there's not enough resources :-("

teletype "Now we change overcommit values in the OsDpl resource to the default (8.0):"
telerun kubectl -n openstack patch osdpl osh-dev --type=merge --patch '{"spec":{"features":{"nova":{"allocation_ratios":null}}}}'
until [ "$(kubectl get osdplst osh-dev -ojsonpath='{.status.osdpl.state}')" == "APPLYING" ]; do sleep 10; done
echo started applying...
until [ "$(kubectl get osdplst osh-dev -ojsonpath='{.status.osdpl.state}')" == "APPLIED" ]; do sleep 10; done
teletype "Some time later..."
telerun kubectl -n openstack get osdplst

teletype "However the overcommit value on resource provider did not change:"
telerun openstack resource provider inventory list $first_resprov_id
teletype "This is because the changes to spec:features:nova:allocation_ratios"
teletype "affect ONLY NEW ADDED COMPUTES!"
teletype "like during initial deployment or when adding new compute nodes."
echo
sleep 3
teletype "To change the values for existing node, we now can use Placement API"
teletype "following these steps:"
echo
sleep 2
teletype "Find the hypervisor we need to change values for (we have single one):"
telerun openstack hypervisor list
hv_hostname=$(openstack hypervisor list -f value -c 'Hypervisor Hostname')
teletype "Find the corresponding placement resource provider using hypervisor hostname:"
telerun openstack resource provider list --name $hv_hostname
teletype "Increase cpu allocation ratio to what we aim for (default 8):"
telerun openstack resource provider inventory set --amend $first_resprov_id --resource VCPU:allocation_ratio=8
teletype "Note the --amend - w/o it all the fields of the resource provider"
teletype "will be overriden with the values provided,"
teletype "but with --amend only the specific value is updated."

teletype "Now let's delete the faulty instance and try again:"
telerun openstack server delete does-not-fit --wait
telerun openstack server --os-compute-api-version 2.37 create now-it-fits --nic none --flavor maxCPU --image Cirros-6.0 --wait
teletype "Success! and no nova-compute restart required :-)"

teletype "Now let's add a new compute node and verify that the it is registered"
teletype "with overcommit values from OsDpl right from the start."
teletype "Label the node with appropriate label"
teletype "(this is not the only label that might needed,"
teletype "but this is one I removed to take the node out):"
telerun kubectl label node $spare_node openstack-compute-node=enabled
teletype "Wait for compute node to be up and register itself in placement:"
until [ "$(openstack resource provider list -f value | wc -l)" == "2" ]; do sleep 10; done
telerun openstack resource provider list
teletype "Now we have two!"
teletype "Check the overcommit on the new resource provider:"
second_resprov_id=$(openstack resource provider list -f value -c uuid | grep -v $first_resprov_id)
telerun openstack resource provider inventory list $second_resprov_id
teletype "New values are in correspondence with OsDpl."
sleep 3
clear
teletype "To sum up:"
teletype "- since MOSK 23.1 it is possible to set compute overcommits as part of spec.features of OsDpl;"
teletype "- the values set in OsDpl only affect newly added compute nodes;"
teletype "- for existing compute nodes it is now possible AND RECOMMENDED to change overcommit via Placement API."
echo
teletype "Happy OpenStacking! :-)"
# rollback
telerun openstack server delete now-it-fits it-fits-1 it-fits-2
