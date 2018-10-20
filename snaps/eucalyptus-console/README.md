# Install

You can install this snap from:

  https://snapcraft.io/eucalyptus-console

# Configure

For use with your Eucalyptus cloud you will need to configure the
`ufshost`. For example:

```
# snap set eucalyptus-console ufshost=ec2.mycloud-10-10-10-42.euca.me
```

Defaults and settings are:

```
# snap set eucalyptus-console host=127.0.0.1
# snap set eucalyptus-console port=8888
# snap set eucalyptus-console ufshost=localhost
# snap set eucalyptus-console ufsport=8773
```

# Usage

Once installed and configured use the `eucalyptus-console.eucaconsole`
command to bring up the console web UI.

