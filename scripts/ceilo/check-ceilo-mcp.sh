#!/bin/bash

# Check aliveness of ceolimeter-agent-notification service on MCP nodes
# Run this on cfg node, needs clouds.yaml with 'admin_identity' cloud name
# set up for your account and access to OpenStack API with this cloud.

echo "==============="
echo "ceilometer-agent-notification status and logs from all mdb nodes"
sudo salt 'mdb0*' cmd.run 'systemctl status ceilometer-agent-notification; echo "------"; tail /var/log/ceilometer/ceilometer-agent-notification.log; echo "------"; date'
echo ""
echo "==============="
echo "Current date is $(date -Iseconds)"
echo "==============="
date_start=${1:-$(date --date '10 minutes ago' -Iminutes)}
for n in $(openstack --os-cloud admin_identity server list -f value -c ID); do
	echo "Instance $n cpu utilization samples since $date_start"
	openstack --os-cloud admin_identity metric measures show cpu_util -r $n --start ${date_start}
done
