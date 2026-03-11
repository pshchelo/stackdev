# Manual multi-node DevStack

Example is for one node controller + compute and one compute.

Note: Some things in this setup could be missing still, and not everything
might work as expected.

## Controller

Setup controller + compute as usual DevStack All-in-One

## Compute node

See `compute-*-local.conf` for examples and services that must/should/could
be enabled on the compute node.

The custom steps to configure the Devstack deployment of extra compute node
are:

1. Deploy the controller node first.
1. In the local.conf of the compute node, set the `SERVICE_HOST`
   to address of the controller node, where the compute can access
   rmq, mysql and other services.
   This is most probably the IP or hostname you see in the public endpoints
   of the keystone catalog when accessing it from the controller node.
1. Copy over the TLS certs. From controller node, run
   ```
   scp -r /opt/stack/data/CA /opt/stack/data/*.pem <address of compute node>:/opt/stack/data
   ```
1. Run stack.sh on the compute node as usual.
1. On the controller node, run `tools/discover_hosts.sh`.
1. Setup mutual access for migrations to work, see section below.

## Migration

In order for VM migrations to work between two nodes, the following must be
set up:

- Hostname resolution - nodes must be able to resolve each other names to IP
  address for any protocol, not only SSH.

  - Edit `/etc/hosts` on each node to add the other one's hostname and IP.

- The `$STACK_USER` must be able to SSH into another node as `$STACK_USER`.
  This is because nova runs as `$STACK_USER` and uses SSH to copy files over 
  to the other node during cold migration,
  and some parts of live migration too.

  - Use whatever method of key sharing to setup mutual SSH access 
    for `$STACK_USER`.

- The `root` user must be able to SSH into another node as `$STACK_USER`.
  This is because live migration is orchestrated by the libvirt daemon on 
  the source node, which runs as root, and thus does SSH as root, 
  and the live migration URL scheme as configured by DevStack is 
  `qemu+ssh://$STACK_USER@<hostname>/system`.

  - Assuming you have the SSH key for the node as `~/.ssh/id_rsa`, copy it over
    to `/root/.ssh/id_rsa` and create the following minimal SSH config file
    for `root` user as `/root/.ssh/config` 
    (replace user with your `$STACK_USER`):
    ```
    IdentityFile /root/.ssh/id_rsa
    IdentitiesOnly yes
    User ubuntu
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
    ```
