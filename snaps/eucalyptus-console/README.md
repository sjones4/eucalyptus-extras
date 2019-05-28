# Install

You can install this snap from:

  https://snapcraft.io/eucalyptus-console

An example of installing on CentOS 7 is:

```
# # snap support
# yum install snapd
# systemctl enable --now snapd.socket
# ln -s /var/lib/snapd/snap /snap
# snap install core
#
# # console
# snap install eucalyptus-console
# snap set eucalyptus-console ufshost=example-10-10-10-10.euca.me
```

# Configure

For use with your Eucalyptus cloud you will need to configure the
`ufshost`. For example:

```
# snap set eucalyptus-console ufshost=ec2.mycloud-10-10-10-42.euca.me
```

All configuration options and the defaults values are:

```
# snap set eucalyptus-console console-host=127.0.0.1
# snap set eucalyptus-console console-port=8888
# snap set eucalyptus-console host=0.0.0.0
# snap set eucalyptus-console http-port=80
# snap set eucalyptus-console https-port=443
# snap set eucalyptus-console ufshost=localhost
# snap set eucalyptus-console ufsport=8773
```

To show the current configuration:

```
# snap get eucalyptus-console
```

# Usage

The console should be run as as service, but can also be run via
command for a single user.

## Service
Services will launch on install and can be manually controlled using:

```
# snap stop eucalyptus-console
# snap start eucalyptus-console
```

To stop services and prevent startup on next boot, use:

```
# snap stop --disable eucalyptus-console
# snap start --enable eucalyptus-console
```

To check on the current status for services:

```
# snap services eucalyptus-console
```

## Command

The `eucalyptus-console.console` command can be used to bring up the
console web UI in the foreground. This mode is intended for single user
use only.

The console will be accessible via HTTP on the `console-port` (8888 by
default) and the `console-host` must be updated to allow remote access,
but note that this is insecure and not recommended.


