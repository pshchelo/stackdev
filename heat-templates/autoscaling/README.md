# Autoscaling examples with Heat, Ceilometer, Aodh

Basic idea is Heat's Autoscaling Group with attached scaling policies,
and Aodh alarms that hit webhooks of a corresponding scaling policy
when alarm is triggered.

Most examples specifically target Cirros image - very minimal Linux image 
designed to test clouds, widely used in OpenStack testing.

The examples usually use a specially crafted user-data that:

- creates a `cpuload` script inside the instance, that can be used to create
  CPU load (all cores or less), see `cpuload -h` inside the booted instances.
- creates a very minimal "http server" based on `netcat` tool, 
  that answers every request with HTTP 200 OK and server name.

These are meant to facilitate showcasing of loadbalancing and autoscaling.

## asg-aws-old.yaml

Uses AWS-compatible Heat resources wherever possible.

No longer works as it targets `cpu_util` metric that was removed from
Ceilometer somewhere around Stein release.

## asg-gnocchi-old

No longer works as it targets `cpu_util` metric that was removed from
Ceilometer somewhere around Stein release.


## asg-gnocchi.yaml

Should be still working, requires Gnocchi as metric storage.

Almost the same query as Aodh will execute for the alarms in this stack:

```
openstack metric aggregates '(aggregate rate:mean (metric cpu mean))' \
    --resource-type instance \
    --stop now \
    --needed-overlap 0 \
    --granularity 60 \
    server_group=<stack-id>

```

## asg-prom.yaml

Requires Prometheus/Aetos as metric storage.
