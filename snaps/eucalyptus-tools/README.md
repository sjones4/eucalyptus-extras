# Install

You can install this snap from:

  https://snapcraft.io/eucalyptus-tools

though it may be easier to use if you install as a classic snap with access to your existing configuration in $HOME/.euca:

```
# sudo snap install --classic eucalyptus-tools
```

but note that installing with the classic option disables security confinement.


# Usage

Once installed commands are available via the "euca" alias:

```
# euca ec2 describe-instances
```

For use of the regular euca2ools commands you can either use the snap prefix:

```
# eucalyptus-tools.euca-describe-instances
```

or can configure additional aliases:

```
# sudo snap alias eucalyptus-tools.euca-describe-instances euca-describe-instances
# euca-describe-instances
```

The bin/euca2ools-aliases.sh script in this repository can be used to configure aliases for all euca2ools commands. Alternatively the euca2ools_bash_aliases file can be sourced for bash aliases:

```
# . euca2ools_bash_aliases
# euca-describe-instances
```

