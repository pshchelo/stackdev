##############################################################
AutoScaling WebApp using Ceilometer and Neutron Load Balancing
##############################################################

Current version will not work from OpenStack Dashboard (Horizon)
as Horizon can not parse environment declarations as local files.
Upload all files to web and modify ``env_asglb.yaml`` to point to
appropriate HTTP links instead (e.g. use raw links from this repo on GitHub).

Create the stack
================
Launch with:

    heat stack-create asglb -f asglb.yaml -e env_asglb.yaml [-P <parameters>]


Access the web app
==================

Get the URL of the HTTP webapp:

    heat output-show asglb app_lb_url

Curl it to show hostname. Repeat to see the host name alternating.

If not taking any specific actions and depending on settings for size of
auto-scaling group in the template ``asglb.yaml`` some instances might
disappear as Ceilometer detects low CPU activity and
auto scaling down kicks in.

Manual scaling up/down
======================

Show the URLs of the scaling hooks:

    heat output-show asglb scale_[up|down]_hook

``curl -X POST`` to these to force manual scale up or down.
Check by accessing the webapp and observe some hostname added/removed
when repeatedly accessing.

Auto-scaling via Ceilometer
===========================

Get the command to SSH to one of the instances:

    heat output-show asglb ssh_lb_url

SSH access is also load-balanced in a round-robin fashion.
VMs are preloaded with ``cpuload`` script that can be executed via SSH
as follows:

    ``cpuluad`` - load all CPU cores
    ``cpuload -r`` - release the CPU load
    ``cpuload -s`` - status of CPU load (on/off)
    ``cpuload -i`` - identify the host by hostname

Use it to load/release load on CPU and test the auto-scaling via Ceilometer.

The script is taken from ``scripts/cpuload`` file from this very repo
via direct link

   https://raw.githubusercontent.com/pshchelo/stackdev/master/scripts/cpuload

If you do not have access to WWW from where you launch the stack,
download this file locally and modify ``netcat-webapp.yaml`` template to
point to it via ``get_file`` template function.

TODO
====

- create network and subnet on the fly
- create nova key on the fly
  - expose the private key via template output
- add descriptions to parameters
- put constraints on parameters
- move default parameter values to environment
- improve passing the security groups in
- split config to cpuload script config and webapp config
  - might not work on Cirros if it will require multi-part MIME
