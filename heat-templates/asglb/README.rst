##############################################################
AutoScaling WebApp using Ceilometer and Octavia Load Balancing
##############################################################

Current version will not work as-is from OpenStack Dashboard (Horizon)
as Horizon can not parse environment declarations as local files.
Upload all files to web and modify ``env_asglb.yaml``  and
``netcat-webapp.yaml`` to point to appropriate HTTP links instead
(e.g. use raw links from this repo on GitHub).

Create the stack
================

Download all files in this folder locally.

Launch Heat stack with:

    heat stack-create asglb -f asglb.yaml -e env_asglb.yaml [-P <parameters>]


Access the web app
==================

Get the URL of the HTTP webapp:

    openstack stack output show asglb app_lb_url

Curl it to show hostname. Repeat to see the host name alternating.

If not taking any specific actions and depending on settings for size of
auto-scaling group in the template ``asglb.yaml`` after a certain time some
instances might disappear as Ceilometer detects low CPU activity and
auto scaling down kicks in.

Manual scaling up/down
======================

Show the URLs of the scaling hooks:

    openstack stack output show asglb scale_[up|down]_hook

``curl -X POST`` to these to force manual scale up or down.
Check by accessing the webapp and observe some hostname added/removed
when repeatedly accessing.
Again, Ceilometer might bring the number of instances back per
actual alarm state.

Auto-scaling via Ceilometer
===========================

Get the command to SSH to one of the instances:

    openstack stack output show asglb ssh_lb_url

SSH access is also load-balanced in a round-robin fashion.
VMs are preloaded with ``cpuload`` script that can be executed via SSH
as follows:

- ``cpuluad`` - load all CPU cores
- ``cpuload -r`` - release the CPU load
- ``cpuload -s`` - status of CPU load (on/off)
- ``cpuload -i`` - identify the host by hostname

Use it to load/release load on CPU and test the auto-scaling via Ceilometer.

The script is taken from ``scripts/heat/cpuload`` file from this very repo.

TODO
====

- improve passing the security groups in
- split config to cpuload script config and webapp config

  - might not work on Cirros if it will require multi-part MIME
