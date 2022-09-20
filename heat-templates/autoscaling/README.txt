Almost the same query as Aodh will execute for the alarms in this stack:

openstack metric aggregates --resource-type instance '(aggregate rate:mean (metric cpu mean))' server_group=<stack-id> --stop now --needed-overlap 0 --granularity 60
