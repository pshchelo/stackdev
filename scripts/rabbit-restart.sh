#!/usr/bin/env bash

function check_nova_service {
    local update_at
    sleep 30
    updated_at=$(openstack --os-cloud devstack-admin compute service list --service nova-compute -f value -c "Updated At")
    for i in {1..5}; do
      echo "Sleeping..."
      sleep 10
      if [[ $(openstack --os-cloud devstack-admin compute service list --service nova-compute -f value -c 'Updated At') != "$updated_at" ]]; then
        return 0
      fi
    done
    return 1
}

#for attempt in {1..20}; do
attempt=0
while true; do
     attempt=$((attempt+1))
     echo "Restarting rabbit for $attempt time"
     sudo systemctl restart rabbitmq-server

     echo "Checking nova-compute"

     if check_nova_service; then
         echo "Nova heartbeat recieved."
     else
         echo "Nova compute is stuck!"
         break
     fi
     echo "$(openstack --os-cloud devstack-admin compute service list)"
done

