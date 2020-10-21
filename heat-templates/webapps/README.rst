##############################################
Set of Heat templates to create (test) webapps
##############################################

Use as::

    heat stack-create <stack name> -f webapp.yaml -e <environment-file>

Please check the ``webapp.yaml`` for supported parameters and outputs.

Available environments:

``cirros-nc.yaml``
    Uses minimal Cirros image and netcat based webapp reporting hostname,
    specifically tailored for this image.

``fedora-python.yaml``
  Uses ``fedora-heat-test-image`` and Python's SimpleHTTPServer,
  reports hostname.
  Generally any image with Python3 or Python installed could be used.

``fedora-tomcat.yaml``
  Uses ``fedora-heat-test-image``, installs Java, Tomcat and simple Tomcat servlet.
  Does not support app port assignment, always runs on default 8080 Tomcat port.
