######################
Sanity Check templates
######################

Purpose is to use Heat to test several OpenStack services together,
e.g. that DevStack is installed and working correctly.

These templates create a given number of **rich servers** -
a server with volume attached and Neutron floating ip associated,
with a simplest webapp running
(needs python installed on the VM OS, so no cirros).

To create a number N of them you must have all three files locally,
then run

.. code:: shell

  heat stack-create sanity -f sanity-neutron.yaml -e sanity-registry.yaml -P group_size=N

and wait for ``sanity`` stack to become CREATE_COMPLETE.
Then you can get the list of floating IPs assigned to servers with

.. code:: shell

  heat output-show sanity webapp_ips

and try to access a single webapp by e.g.

.. code:: shell

  curl FLOATING_IP

It should report the host name of the server.
You should also be able to ping the servers and access them via SSH using
the Nova key pair provided as ``server_key`` parameter.

Note
  Defaults for parameters are taken for my DevStack,
  so you should change them
  or provide other values to ``stack-create`` when needed.
