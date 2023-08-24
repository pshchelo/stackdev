# Running temtest tests locally

1. Simulate proper tempest run by running nothing (replace 'script:' is OsDpl
   with `sleep infinity`).
2. Fetch the tempest config and blacklist file from the running tempest pod.
3. Change some params in tempest.conf, see `adapt-tempest-conf.sh`.
4. ?Something else?
4. Run tempest as usual, with that config and blacklist file.
