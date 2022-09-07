kopenstack flavor create m1.nano --ram 128 --disk 1 --vcpu 1
kopenstack user create demo --password admin --domain default
kopenstack user create alt_demo --password admin --domain default
kopenstack project create demo --domain default
kopenstack role add member --user demo --user-domain default --project demo --project-domain default
kopenstack role add member --user alt_demo --user-domain default --project demo --project-domain default
