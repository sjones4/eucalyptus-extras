# Eucalyptus Testing Utilities

Configuration
------
A **_nephoria-config.sh_** script in the working or home directory will be used by install and test scripts:

```
CLC_IP=10.20.10.63
NEPHORIA_OPTS="--worker-password=foobar"
N4J_OPTS="-Dpassword=foobar"
IMAGE_BASE_URL=http://MY_IMAGE_HOST/MY_IMAGE_PATH
```

This is useful for setting local options such as the IP of the cloud being tested and the SSH user/password to use.

Installation
------
The **_nephoria-install.sh_** script can be used to quickly install testing frameworks on RHEL/CentOS 7 systems.

This will install the rpms as documented for each project (e.g. git java-1.8.0-openjdk-devel python-devel)

By default the install creates the following in the working directory:

* adminapi - a git clone for eucalyptus/adminapi#master
* nephoria - a git clone for eucalyptus/nephoria#master
* nephoria-env - a python virtual environment for adminapi/nephoria
* n4j - a git clone for sjones4/n4j#devel-4.4

Git clones are shallow, so you need to run:

```
git fetch --unshallow
```

If you need the full history.

Testing
------
To run tests activate the virtual environment:

```
. nephoria-env/bin/activate
```

Then run the supplied scripts as desired:

```
n4j-test.sh
nephoria-test.sh
```

Test output will be displayed on the console and available in log files for later use.

