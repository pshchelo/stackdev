# Running temtest tests locally

## Requirements
- kubectl with context suited for listing pods and copying files from them
- `crudini` tool for ini file modification

## Procedure
1. Install tempest and required plugins in a virtualenv, activate that venv.
2. Simulate proper tempest run by running nothing (replace 'script:' is OsDpl
   with `sleep infinity`).
   - this will generate all the required config files from OsDpl.
3. Once tempest-run-test-... pod is running, run `adapt-tempest-conf.sh`
   that will:
  - fetch the tempest config and blacklist file from the running tempest pod
  - fetch some additional things like images/binareis to use
  - change some params in tempest.conf like paths and API urls
  - generate a script for you to run with the above config and blacklist
4. Run the generated sctipt, all passed arguments are passed to `tempest run`.
