# Running Horizon locally against MOSK

- run `adapt-horizon.sh` script to fetch all configs from running horizon pod
  and adapt it to running locally
- move modified local_settings.py  to `openstack_dashboard/local/` of Horizon
  repo
  - only this file is to be moved, it points back to `openstack-dashboard` dir
    in your current folder with files downloaded from pod
- init horizon venv with `tox -erunserver --notest`
- manually install required Horizon plugins into `.tox/venv` virtualenv,
  copy their settings as required:
  - config snippets to `openstack_dashboard/local/`
  - policy files to `openstack-dashboard` dir with configs downloaded from pod
    (not in Horizon repo)
- run horizon as `tox -erunserver`
