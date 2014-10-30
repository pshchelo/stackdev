=============
Demo overview
=============

Schedule
========
Total time: 60m.

- Introduction: 10m
- Welcome message: 2m
- Lab & Architecture: 4m
- Changes in components: 4m
- Ceilometer & Heat: 30m

  - Templates: 5m
  - Deployment: 3m
  - Scaling demo: 10m
  - Ceilometer overview: 10m
  - Spare time: 2m

- Trove demo: 10m
- Q&A: 10m

Prerequisites for Heat
----------------------
- put required images to Glance
- create a Nova key pair, save the private key

  - needed it just to stress VM CPU and demonstrate behavior under load

- can not assign security groups to AWS Load Balancer resource in Heat, so fix the default security group

  - allow incoming ports 80, 8080, 22

Heat + Ceilometer Demo
======================
- create Heat stack from demo template
- supply needed template parameters like nova key name
- wait for stack to become CREATE_COMPLETE plus some time for webapp to be completely installed on the instances
- assign floating ip to the load balancer manually

  - can not assign Floating IP to the AWS LoadBalancer resource in Heat

- access the webapp via load balancer from where floating ip network is accessible

  - observe alternating host names reported by the webapp when repeatedly accessing it

- Ceilometer:

  - Meters

    - ``ceilometer meter-list``

  - Resource filter (resource is one of used VMWare instances)

    - ``ceilometer sample-list -m cpu_util -q resource_id={resource_id}``

  - Limits

    - ``ceilometer sample-list -m cpu_util limit 1``

  - Resource list

    - ``ceilometer resource-list``
    - Choose one resource id

      - ``ceilometer resource-show {resource_id}``

  - Alarms

    - ``ceilometer alarm-list``

    - Choose id of one alarm

      - ``ceilometer alarm-show {alarm_id}``
      - ``ceilometer alarm-history {alarm_id}``

- assign a floating ip to one of the webapp vms (just to be able to access it for stress-loading)
- stress this webapp vm

  - ``ssh ec2-user@vm-ip -i privatekeyfile "stress -c 2 &"``

- observe a third instance spin up in nova, wait some more for webapp to initialize

- Ceilometer

  - list samples from the stressed vm:

    - ``ceilometer sample-list -m cpu_util -q resource_id={stressed_vm_id} --limit 10``

  - confirm that alarm went off

    - ``ceilometer alarm-list``
    - ``ceilometer alarm-show -a {CPUhighAlarm_id}``

- keep accessing the webapp via load balancer
- observe the host name of the third vm appear in webapp
- release stress from the vm

  - ``ssh ec2-user@vm-ip -i keyfile "pkill stress"``

- observe vm disappearing from nova
- Ceilometer

  - get some statistics

    - overall

      - ``ceilometer statistics -m cpu_util``
      - ``ceilometer statistics -m memory.usage``

    - specific to a resource

      - ``ceilometer statistics -m cpu_util -q resource_id={loadbalancer_vm_id} -p 60 -f avg``

Trove
=====
