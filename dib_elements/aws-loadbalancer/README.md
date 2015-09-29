Install the Heat cfntools (for CloudFormation), HAProxy and other packages 
to create an image usable as AWS::ElasticLoadBalancing::LoadBalancer 
resource in Heat.

Not using existing haproxy element as it depends on `os-*-config` elements
that are not needed here.
