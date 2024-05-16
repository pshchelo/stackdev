# Manual multi-node DevStack

Example is for one node controller + compute and one compute.

Note: Some things in this setup could be missing still, and not everything
might work as expected.

## Controller

Setup controller + compute as usual DevStack All-in-One

## Compute node

see `compute-*-local.conf` for examples and services that must/should/could
be enabled on the compute node.

The custom steps to configure the devstack deployment of extra compute node
are:

0. Deploy the controller node first.
1. In the local.conf of the compute node, set the `SERVICE_HOST`
   to address of the controller node, where the compute can access
   rmq, mysql and other services.
   This is most probably the IP or hostname you see in the public endpoints
   of the keystone catalog when accessing it from the controller node.
2. Setup mutual SSH access. Controller and compute must be able to ssh to each
   other for live migration to work.
3. Copy over the TLS certs. From controller node, run
   ```
   scp -r /opt/stack/data/CA /opt/stack/data/*.pem <address of compute node>:/opt/stack/data
   ```
4. Run stack.sh on the compute node as usual.
5. On the controller node, run `tools/discover_hosts.sh`.
