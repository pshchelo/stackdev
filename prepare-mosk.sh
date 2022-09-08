kopenstack flavor create m1.nano --ram 128 --disk 1 --vcpu 1
kopenstack user create --or-show demo --password admin --domain default
kopenstack user create alt-demo --or-show --password alt-demo --domain default
kopenstack project create --or-show demo --domain default
kopenstack role add member --user demo --user-domain default --project demo --project-domain default
kopenstack role add member --user alt-demo --user-domain default --project demo --project-domain default
